import os
import json
import shutil
import scrapbook as sb
import importlib

from airflow.sdk import task
from datetime import timedelta, datetime
from airflow.models import DAG
from airflow.providers.papermill.operators.papermill import PapermillOperator

path = os.getcwd()
config_file = f"{path}/dags/process_wwi_rollback_bq.json"

f = open(config_file,)
config = json.load(f)
f.close()

cutoff_date = config["cutoffDate"]
process_directory = f"{path}{config["processDirectory"]}"
sql_utilities_file = f"{path}{config["sqlUtilitiesPath"]}"
kernel_name = config["kernelName"]
no_of_load_tables_per_process = config["noOfLoadTablesPerProcess"]
no_of_warehouse_dimension_tables_per_process = config["noOfWarehouseDimensionTablesPerProcess"]
no_of_warehouse_fact_tables_per_process = config["noOfWarehouseFactTablesPerProcess"]
gcp_credential = config["gcpCredential"]

print(f"cutoff_date: {cutoff_date}")
print(f"process_directory: {process_directory}")
print(f"sql_utilities_file: {sql_utilities_file}")
print(f"kernel_name: {kernel_name}")
print(f"no_of_load_tables_per_process: {no_of_load_tables_per_process}")
print(f"no_of_warehouse_dimension_tables_per_process: {no_of_warehouse_dimension_tables_per_process}")
print(f"no_of_warehouse_fact_tables_per_process: {no_of_warehouse_fact_tables_per_process}")
print(f"gcp_credential: {gcp_credential}")

os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = gcp_credential

spec = importlib.util.spec_from_file_location("sql_utils", sql_utilities_file)
sql_utils = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sql_utils)

def get_load_history_date_by_loaddate(new_cutoff_date):
    sql = sql_utils.get_sql_from_script(
        path=config["loadHistoryDate"]["loadLoadHistoryDateTable"], 
        values=[
            { "name": "Schema", "value": config["loadHistoryDate"]["schema"] },
            { "name": "Table", "value": config["loadHistoryDate"]["table"] },
            { "name": "Database", "value": config["destination"]["database"] },
            { "name": "LoadDate", "value": new_cutoff_date }
        ], 
        tables=[],
        directory=f"{process_directory}/"
    )

    return sql_utils.select_sql(
        conn=config["destination"]["conn"], 
        sql=sql, 
        database_type=config["destination"]["databaseType"], 
        result_type="dictionary", 
        database=config["destination"]["database"], 
        spark_jars=config["sparkJars"], 
        spark_master=config["sparkMaster"], 
        set_timestamp_tostring=False, 
        add_column_names=False, 
        spark_load_sql=True
    )

def get_warehouse_history_date_by_loaddate(new_cutoff_date):
    sql = sql_utils.get_sql_from_script(
        path=config["warehouseHistoryDate"]["loadWarehouseHistoryDateTable"], 
        values=[
            { "name": "Schema", "value": config["warehouseHistoryDate"]["schema"] },
            { "name": "Table", "value": config["warehouseHistoryDate"]["table"] },
            { "name": "Database", "value": config["destination"]["database"] },
            { "name": "LoadDate", "value": new_cutoff_date }
        ], 
        tables=[],
        directory=f"{process_directory}/"
    )

    return sql_utils.select_sql(
        conn=config["destination"]["conn"], 
        sql=sql, 
        database_type=config["destination"]["databaseType"], 
        result_type="dictionary", 
        database=config["destination"]["database"], 
        spark_jars=config["sparkJars"], 
        spark_master=config["sparkMaster"], 
        set_timestamp_tostring=False, 
        add_column_names=False, 
        spark_load_sql=True
    )

load_history_date_data = get_load_history_date_by_loaddate(cutoff_date)
warehouse_history_date_data = get_warehouse_history_date_by_loaddate(cutoff_date)
print(f"load_history_date_data: {load_history_date_data}")
print(f"warehouse_history_date_data: {warehouse_history_date_data}")

default_args = {
    "owner": "Airflow",
    "start_date": datetime(2025, 1, 1)
}

def get_rollback_load_wwi(idx_process, tables, load_archive_path):
    return PapermillOperator(
        task_id=f"rollback_load_wwi{idx_process}",
        input_nb=f"{load_archive_path}/load_wwi.ipynb",
        output_nb=f"{load_archive_path}/outputs/rollback_load_wwi{idx_process}_{cutoff_date}_output.ipynb",
        parameters={
            "fromNotebook": False,
            "configFile": f"{load_archive_path}/load_wwi.json",
            "newCutoffDate": cutoff_date,
            "tables": tables,
            "sqlUtilFilePath": f"{load_archive_path}/modules/sql_utilities.py",
            "script_directory": f"{load_archive_path}/",
            "archivePath": "",
            "is_rollback": True
        },
        kernel_name=kernel_name
    )

def get_rollback_warehouse_wwi(idx_process, tables_name, tables, warehouse_archive_path, load_archive_path):
    dimension_tables = []
    fact_tables = []

    if tables_name == "dimensionTables":
        dimension_tables = tables
    else:
        fact_tables = tables

    return PapermillOperator(
        task_id=f"rollback_warehouse_wwi_{tables_name}{idx_process}",
        input_nb=f"{warehouse_archive_path}/warehouse_wwi.ipynb",
        output_nb=f"{warehouse_archive_path}/outputs/rollback_warehouse_wwi_{tables_name}{idx_process}_{cutoff_date}_output.ipynb",
        parameters={
            "fromNotebook": False,
            "loadConfigFile": f"{load_archive_path}/load_wwi.json",
            "configFile": f"{warehouse_archive_path}/warehouse_wwi.json",
            "newCutoffDate": cutoff_date,
            "dimension_tables": dimension_tables,
            "fact_tables": fact_tables,
            "sqlUtilFilePath": f"{warehouse_archive_path}/modules/sql_utilities.py",
            "archivePath": "",
            "script_directory": f"{warehouse_archive_path}/",
            "is_rollback": True
        },
        kernel_name=kernel_name
    )

def get_rollback_load_wwi_processes(load_archive_path):
    load_wwi = []
    idx = 0
    tables = []
    idx_process = 1
    idx_table = 0

    f = open(f"{load_archive_path}/load_wwi.json")
    load_config = json.load(f)
    f.close()

    if no_of_load_tables_per_process == 0:
        print(f"tables in load_wwi{idx_process}: {load_config["tables"]}")
        load_wwi.append(get_rollback_load_wwi(idx_process, load_config["tables"], load_archive_path))
    else:
        for table in load_config["tables"]:
            tables.append(table)
            idx = idx + 1
            idx_table = idx_table + 1

            if idx == no_of_load_tables_per_process or idx_table == len(load_config["tables"]):
                print(f"tables in load_wwi{idx_process}: {tables}")
                load_wwi.append(get_rollback_load_wwi(idx_process, tables, load_archive_path))
                idx = 0
                idx_process = idx_process + 1
                tables = []
    
    return load_wwi

def get_rollback_warehouse_wwi_processes(tables_name, no_tables_per_process, warehouse_archive_path, load_adrchive_path):
    warehouse_wwi = []
    idx = 0
    tables = []
    idx_process = 1
    idx_table = 0

    f = open(f"{warehouse_archive_path}/warehouse_wwi.json")
    warehouse_config = json.load(f)
    f.close()

    if no_tables_per_process == 0:
        print(f"tables in warehouse_wwi_{tables_name}{idx_process}: {warehouse_config[tables_name]}")
        warehouse_wwi.append(get_rollback_warehouse_wwi(idx_process, tables_name, warehouse_config[tables_name], warehouse_archive_path, load_adrchive_path))
    else:
        for table in warehouse_config[tables_name]:
            tables.append(table)
            idx = idx + 1
            idx_table = idx_table + 1

            if idx == no_tables_per_process or idx_table == len(warehouse_config[tables_name]):
                print(f"tables in warehouse_wwi_{tables_name}{idx_process}: {tables}")
                warehouse_wwi.append(get_rollback_warehouse_wwi(idx_process, tables_name, tables, warehouse_archive_path, load_adrchive_path))
                idx = 0
                idx_process = idx_process + 1
                tables = []
    
    return warehouse_wwi

@task
def single_task():
    print(f"single_task")

@task
def load_date_not_found_task():
    raise Exception(f"Cutoff date {cutoff_date} not found in Load or Warehouse load dates.")

with DAG(
    dag_id="process_wwi_rollback",
    default_args=default_args,
    dagrun_timeout=timedelta(minutes=60)
) as dag:
    if len(load_history_date_data) == 0 or len(warehouse_history_date_data) == 0:
        (
            load_date_not_found_task()
        )
    else:
        single_task_placeholder = single_task() 
        single_task_placeholder2 = single_task()
        rollback_load_wwi = get_rollback_load_wwi_processes(load_history_date_data[0]["ArchivePath"])
        warehouse_wwi_dimension = get_rollback_warehouse_wwi_processes("dimensionTables", no_of_warehouse_dimension_tables_per_process, warehouse_history_date_data[0]["ArchivePath"], load_history_date_data[0]["ArchivePath"])
        warehouse_wwi_fact = get_rollback_warehouse_wwi_processes("factTables", no_of_warehouse_fact_tables_per_process, warehouse_history_date_data[0]["ArchivePath"], load_history_date_data[0]["ArchivePath"])

        (
            rollback_load_wwi
            >>
            single_task_placeholder
            >>
            warehouse_wwi_dimension
            >>
            single_task_placeholder2
            >>
            warehouse_wwi_fact
        )