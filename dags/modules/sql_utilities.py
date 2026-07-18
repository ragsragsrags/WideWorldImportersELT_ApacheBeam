import pyodbc
import json
import re
import os
import pandas as pd
import numpy as np

from pyspark.sql import SparkSession
from pyspark.sql.functions import date_format, col
from pyspark.sql.types import TimestampType
from google.cloud import bigquery
from datetime import datetime

osPath = os.getcwd()
spark_executor_memory = "3g"
spark_driver_memory = "3g"
spark_executor_cores = "2"
spark_cores_max = "2"
spark_network_timeout = "600s"
spark_executor_heartbeat_interval = "599s"

def initialize_spark_session(master, jdbc_url, jars, executor_memory, driver_memory, executor_cores, cores_max, network_timeout, executor_heartbeat_interval):
    global spark_executor_memory
    global spark_driver_memory
    global spark_executor_cores
    global spark_cores_max
    global spark_network_timeout
    global spark_executor_heartbeat_interval
    
    spark_executor_memory = executor_memory
    spark_driver_memory = driver_memory
    spark_executor_cores = executor_cores
    spark_cores_max = cores_max
    spark_network_timeout = network_timeout
    spark_executor_heartbeat_interval = executor_heartbeat_interval

    return get_spark_session(master, jdbc_url, jars, True)

def get_spark_session(spark_master, jdbc_url, jars, show_properties = False):
    if show_properties == True:
        print(f"spark_executor_memory: {spark_executor_memory}")
        print(f"spark_driver_memory: {spark_driver_memory}")
        print(f"spark_executor_cores: {spark_executor_cores}")
        print(f"spark_cores_max: {spark_cores_max}")
        print(f"spark_network_timeout: {spark_network_timeout}")
        print(f"spark_executor_heartbeat_interval: {spark_executor_heartbeat_interval}")
    
    if spark_master == "local[*]":
        sparkSession = (
            SparkSession.builder 
                .config(
                    "spark.driver.host", 
                    "localhost"
                )
                .master(spark_master)
                .appName("load_wwi")
                .config("spark.jars", jars)
                .config("writeMethod", "direct")    
                .getOrCreate()
        )
    else:
        sparkSession = (
            SparkSession.builder 
                .master(spark_master)
                .appName("load_wwi")
                .config("spark.jars", jars)
                .config("writeMethod", "direct")
                .config("spark.executor.memory", spark_executor_memory)
                .config("spark.driver.memory", spark_driver_memory)
                .config("spark.executor.cores", spark_executor_cores)
                .config("spark.cores.max", spark_cores_max)
                .config("spark.network.timeout", spark_network_timeout)
                .config("spark.executor.heartbeatInterval", spark_executor_heartbeat_interval)
                .getOrCreate()
        )

    # set spark connection
    if jdbc_url != "":
        df = (
            sparkSession.read
                .format("jdbc")
                .option("url", jdbc_url)
                .option("dbtable", "(SELECT 1 AS SourceDatabase) AS SourceDatabase"
            )
            .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver")
            .load()
        )

    return sparkSession

def stop_spark_session():
    active_spark_session = SparkSession.getActiveSession()
        
    if active_spark_session:
        active_spark_session.stop()

def get_values_from_regex_pattern(text, pattern):
    return [
        str.lstrip(str.rstrip(string)) 
        for string 
        in list(
            dict.fromkeys(
                re.findall(
                    pattern, 
                    text, 
                    flags=re.DOTALL | re.IGNORECASE
                )
            )
        )
    ]

def replace_sql_values(sql, values = []):
    if len(values) > 0:
        values_to_replace = get_values_from_regex_pattern(sql, "<<(.*?)>>")
    
        for val in values_to_replace:
            key = "<< " + val + " >>"
            result = next((item for item in values if item['name'] == val), None)
            
            if result is not None:
                sql = sql.replace(key, result["value"])

    return sql

def replace_sql_tables(sql, tables = [], database_type = "mssql"):
    if len(tables) > 0:
        tables_to_replace = get_values_from_regex_pattern(sql, "{{(.*?)}}")
    
        for table in tables_to_replace:
            key = "{{ " + table + " }}"
            result = next((item for item in tables if item['name'] == table), None)
            
            if result is not None:
                if database_type == "mssql" or database_type == "spark-mssql": 
                    sql = sql.replace(key, f"[{result["schema"]}].[{result["table"]}]")
                elif database_type == "bigquery" or database_type == "spark-bigquery":
                    sql = sql.replace(key, f"`{result["database"]}.{result["schema"]}.{result["table"]}`")

    return sql

def get_sql_from_script(path, values = [], tables = [], database_type = "mssql", directory = ""):
    sql = ''
    
    # path = f"{osPath}/{path}"
    
    with open(f"{directory}{path}", 'r', encoding='utf-8') as f:
        sql = f.read()

    sql = replace_sql_values(sql, values)
    sql = replace_sql_tables(sql, tables, database_type)

    return sql

def select_sql(conn, sql, database_type, result_type = "dictionary", database = "", spark_jars = "", spark_master = "", set_timestamp_tostring = False, add_column_names = False, spark_load_sql = False):
    if database_type == "mssql":
        return select_sql_mssql(conn, sql, result_type, add_column_names)
    elif database_type == "spark-mssql":
        if spark_load_sql == False:
            return select_sql_spark_mssql(conn, sql, spark_jars, spark_master, result_type, set_timestamp_tostring)
        else:
            return select_spark_sql_mssql(conn, sql, spark_master, spark_master)
    elif database_type == "spark-bigquery":
        if spark_load_sql == False:
            return select_sql_spark_bigquery(sql, spark_master, spark_jars, result_type, set_timestamp_tostring)
        else:
            return select_sql_bigquery(sql, database)
        
def select_sql_mssql(conn, sql, result_type, add_column_names = False):
    conn = pyodbc.connect(conn)
    cursor = conn.cursor()
    cursor.execute(sql)

    column_names = [desc[0] for desc in cursor.description]
    
    rows = cursor.fetchall()

    results = []

    if add_column_names == True:
        result = ()
        
        for col in column_names:
            result += (col,)
        
        results.append(result)

    for row in rows:
        row_dict = dict(zip(column_names, row))
        
        if result_type == "dictionary":
            result = {}
            for col in column_names:
                result[col] = row_dict[col]
        elif result_type == "tuple":
            result = ()
            for col in column_names:
                result += (row_dict[col],)

        results.append(result)

    conn.close()

    return results

def select_sql_spark_mssql(conn, sql, jars, master, result_type, set_timestamp_tostring = False):
    spark = get_spark_session(master, conn, jars)
    
    sql = "( " + sql + " ) Data"  

    result = (
        spark.read
            .format("jdbc")
            .option("url", conn)
            .option("dbtable", sql)
            .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver")
            .load()
    )
    
    if result_type == "dictionary":
        if set_timestamp_tostring == True:
            timestamp_fields = [f.name for f in result.schema.fields if isinstance(f.dataType, TimestampType)]
            
            for col_name in timestamp_fields:
                # if col_name in result.columns:
                result = result.withColumn(
                    col_name,
                    date_format(col(col_name), "yyyy-MM-dd HH:mm:ss.SSSSSS")
                )

        result = result.toPandas()

        # for col_name in timestamp_fields:
        #     result[col_name] = pd.to_datetime(result[col_name])
                
        return result.replace({np.nan: None}).to_dict(orient="records")
    elif result_type == "spark-dataframe":
        return result

    return None

def register_spark_table(master, jars, table_id, view_name, database_type, conn):
    if database_type == "spark-msssql":
        spark = get_spark_session(master, conn, jars)
        df = (
            spark.read
                .format("jdbc")
                .option("url", conn)
                .option("dbtable", table_id)
                .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver")
                .load()
        )
        df.createOrReplaceTempView(view_name)
    elif database_type == "spark-bigquery":
        spark = get_spark_session(master, "", jars)
        df = (
            spark.read
                .format("bigquery") 
                .option("table", table_id)
                .option("viewsEnabled", "true")
                .load()
        )
        df.createOrReplaceTempView(view_name)

def select_sql_spark_bigquery(sql, master, jars, result_type, set_timestamp_tostring = False, spark_load_sql = False):
    spark = get_spark_session(master, "", jars)
    
    result = (
        spark.read
            .format("bigquery") 
            .option("query", sql)
            .option("viewsEnabled", "true")
            .load()
    )
    
    if result_type == "dictionary":
        if set_timestamp_tostring == True:
            timestamp_fields = [f.name for f in result.schema.fields if isinstance(f.dataType, TimestampType)]
            
            for col_name in timestamp_fields:
                # if col_name in result.columns:
                result = result.withColumn(
                    col_name,
                    date_format(col(col_name), "yyyy-MM-dd HH:mm:ss.SSSSSS")
                )

        result = result.toPandas()

        # for col_name in timestamp_fields:
        #     result[col_name] = pd.to_datetime(result[col_name])
                
        return result.replace({np.nan: None}).to_dict(orient="records")
    elif result_type == "spark-dataframe":
        return result

    return None

def select_sql_bigquery(sql, database):
    bqClient = bigquery.Client(project=database)
    result = list(bqClient.query(sql).result())

    rows = []
    for row in result:
        rows.append(dict(row.items()))

    return rows

def exec_sql(conn, sql, params, database_type, database = "", spark_master = "", spark_jars = "", spark_insert_sql = False):
    if database_type == "mssql":
        exec_sql_mssql(conn, sql, params)
    elif database_type == "spark-mssql":
        exec_sql_spark_mssql(conn, sql, spark_master, spark_jars)
    elif database_type == "spark-bigquery":
        if spark_insert_sql == False:
            exec_sql_bigquery(sql, database)
        else:
            exec_sql_spark_bigquery(sql, spark_master, spark_jars)

def exec_sql_spark_bigquery(sql, master, jars):
    spark = get_spark_session(master, "", jars)
    spark.sql(sql)

def exec_sql_mssql(conn, sql, params = None):
    conn = pyodbc.connect(conn)
    cursor = conn.cursor()

    if params is None:
        cursor.execute(sql)
    else:
        cursor.execute(sql, params)

    conn.commit()
    cursor.close()
    conn.close()

def exec_sql_spark_mssql(conn, sql, master, jars):
    spark = get_spark_session(master, conn, jars)
        
    connection = spark._jvm.java.sql.DriverManager.getConnection(conn)
    statement = connection.createStatement()
    statement.executeUpdate(sql)

def exec_sql_bigquery(sql, database):
    bqClient = bigquery.Client(project=database)
    bqClient.query(sql).result()

def exec_sql_batch(conn, sql, data, database_type, database = "", table_id = ""):
    if database_type == "mssql":
        exec_sql_batch_mssql(conn, sql, data)
    elif database_type == "spark-mssql":
        exec_sql_batch_spark_mssql(conn, data, table_id)
    elif database_type == "spark-bigquery":
        exec_sql_batch_spark_bigquery(data, table_id)
        
def exec_sql_batch_mssql(conn, sql, data):
    if len(data) > 0:
        conn = pyodbc.connect(conn)
        cursor = conn.cursor()
        cursor.fast_executemany = True
        cursor.executemany(sql, data)

        conn.commit()
        cursor.close()
        conn.close()

def exec_sql_batch_spark_mssql(conn, data, table_id):
    (
        data.write
            .format("jdbc")
            .mode("append")
            .option("url", conn)
            .option("dbtable", table_id)
            .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver")
            .save()
    )

def exec_sql_batch_spark_bigquery(data, table_id):
    (
        data.write 
            .format("bigquery") 
            .option("mode", "append") 
            .option("writeMethod", "direct") 
            .option("writeAtLeastOnce", "true")
            .mode("append") 
            .save(table_id)
    )

def exec_sql_scalar(conn, sql, database_type, database = "", spark_master = "", spark_jars = ""):
    if database_type == "mssql":
        return exec_sql_scalar_mssql(conn, sql)
    elif database_type == "spark-mssql":
        return exec_sql_scalar_spark_mssql(conn, sql, spark_master, spark_jars)
    elif database_type == "spark-bigquery":
        return exec_sql_scalar_bigquery(sql, database)

def exec_sql_scalar_mssql(conn, sql):
    conn = pyodbc.connect(conn)
    cursor = conn.cursor()
    cursor.execute(sql)
    scalar_value =  cursor.fetchval()
    conn.close()

    return scalar_value

def exec_sql_scalar_spark_mssql(conn, sql, master, jars):
    spark = get_spark_session(master, conn, jars)
    connection = spark._jvm.java.sql.DriverManager.getConnection(conn)
    statement = connection.createStatement()
    result = statement.executeQuery(sql)
    
    if result.next():
        return result.getObject(1)
    
    return None

def exec_sql_scalar_bigquery(sql, database):
    bqClient = bigquery.Client(project=database)
    scalar_value = bqClient.query(sql).result()
    scalar_value = (list(scalar_value))[0][0]
    return scalar_value

def select_spark_sql(conn, sql, database_type, database = "", spark_master = "", spark_jars = ""):
    if database_type == "spark-mssql":
        return select_spark_sql_mssql(conn, sql, spark_master, spark_jars)
    else:
        return select_sql(conn, sql, database_type, "dictionary", database, spark_jars, spark_master, False, False, True)

def select_spark_sql_mssql(conn, sql, master, jars):
    spark = get_spark_session(master, conn, jars)
    connection = spark._jvm.java.sql.DriverManager.getConnection(conn)
    statement = connection.createStatement()
    result = statement.executeQuery(sql)
    
    meta = result.getMetaData()
    col_count = meta.getColumnCount()
    col_names = [meta.getColumnName(i) for i in range(1, col_count + 1)]
    col_type_names = [meta.getColumnTypeName(i) for i in range(1, col_count + 1)]
    
    # Convert ResultSet to list of dictionaries
    results = []
    while result.next():
        row_dict = {}
        for i, col in enumerate(col_names, start=1):
            if col_type_names[i - 1].lower().startswith("datetime"):
                row_dict[col] = datetime.strptime(str(result.getTimestamp(i)), "%Y-%m-%d %H:%M:%S.%f")
            else:        
                row_dict[col] = result.getObject(i)  # Handles nulls automatically
        results.append(row_dict)

    return results