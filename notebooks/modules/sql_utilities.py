import pyodbc
import json
import re
import os

osPath = os.getcwd()
# print(f"osPath: {osPath}")

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

def replace_sql_tables(sql, tables = []):
    if len(tables) > 0:
        tables_to_replace = get_values_from_regex_pattern(sql, "{{(.*?)}}")
    
        for table in tables_to_replace:
            key = "{{ " + table + " }}"
            result = next((item for item in tables if item['name'] == table), None)
            
            if result is not None:
                sql = sql.replace(key, f"[{result["schema"]}].[{result["table"]}]")

    return sql

def get_sql_from_script(path, values = [], tables = []):
    sql = ''
    
    path = f"{osPath}/{path}"
    # print(f"path: {path}")

    with open(path, 'r', encoding='utf-8') as f:
        sql = f.read()

    sql = replace_sql_values(sql, values)
    sql = replace_sql_tables(sql, tables)

    return sql

def select_sql(conn, sql, database_type):
    if database_type == "mssql":
        return select_sql_mssql(conn, sql)

def select_sql_mssql(conn, sql):
    conn = pyodbc.connect(conn)
    cursor = conn.cursor()
    cursor.execute(sql)

    column_names = [desc[0] for desc in cursor.description]
    
    rows = cursor.fetchall()

    for row in rows:
        row_dict = dict(zip(column_names, row))
        result = {}

        for col in column_names:
            result[col] = row_dict[col]

        yield result

    conn.close()

def exec_sql(conn, sql, params, database_type):
    if database_type == "mssql":
        exec_sql_mssql(conn, sql, params)

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

def exec_sql_batch(conn, sql, data, database_type):
    if database_type == "mssql":
        exec_sql_batch_mssql(conn, sql, data)

def exec_sql_batch_mssql(conn, sql, data):
    conn = pyodbc.connect(conn)
    cursor = conn.cursor()
    cursor.fast_executemany = True
    cursor.executemany(sql, data)

    conn.commit()
    cursor.close()
    conn.close()

def exec_sql_scalar(conn, sql, database_type):
    if database_type == "mssql":
        return exec_sql_scalar_mssql(conn, sql)    

def exec_sql_scalar_mssql(conn, sql):
    conn = pyodbc.connect(conn)
    cursor = conn.cursor()
    cursor.execute(sql)
    scalar_value =  cursor.fetchval()
    conn.close()

    return scalar_value