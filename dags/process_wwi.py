import os
import json
import shutil

from airflow.sdk import task
from datetime import timedelta, datetime
from airflow.models import DAG
from airflow.providers.papermill.operators.papermill import PapermillOperator

path = os.getcwd()
config_file = f"{path}/dags/process_wwi.json"

f = open(config_file,)
config = json.load(f)
f.close()

cutoff_date = config["cutoffDate"]
load_config_file = f"{path}{config["loadConfigPath"]}"
warehouse_config_file = f"{path}{config["warehouseConfigPath"]}"
no_of_load_tables_per_process = config["noOfLoadTablesPerProcess"]
no_of_warehouse_dimension_tables_per_process = config["noOfWarehouseDimensionTablesPerProcess"]
no_of_warehouse_fact_tables_per_process = config["noOfWarehouseFactTablesPerProcess"]
current_date = datetime.strptime(datetime.now().strftime("%Y-%m-%d 00:00:00"), "%Y-%m-%d %H:%M:%S")
load_directory = f"{path}{config["loadDirectory"]}"
load_process_directory = f"{path}{config["loadProcessDirectory"]}/{config["newCutoffDate"].replace(":", "")}"
warehouse_directory = f"{path}{config["warehouseDirectory"]}"
warehouse_process_directory = f"{path}{config["warehouseProcessDirectory"]}/{config["newCutoffDate"].replace(":", "")}"
sql_utilities_file = f"{path}{config["sqlUtilitiesPath"]}"

print(f"cutoff_date: {cutoff_date}")
print(f"load_config_file: {load_config_file}")
print(f"warehouse_config_file: {warehouse_config_file}")
print(f"no_of_load_tables_per_process: {no_of_load_tables_per_process}")
print(f"current_date: {current_date}")
print(f"load_directory: {load_directory}")
print(f"load_process_directory: {load_process_directory}")
print(f"warehouse_directory: {warehouse_directory}")
print(f"warehouse_process_directory: {warehouse_process_directory}")
print(f"sql_utilities_file: {sql_utilities_file}")

f = open(load_config_file,)
load_config = json.load(f)
f.close()

f = open(warehouse_config_file,)
warehouse_config = json.load(f)
f.close()

default_args = {
    "owner": "Airflow",
    "start_date": datetime(2025, 1, 1)
}

@task
def set_cutoff_date(name: str, cutoff_date, config_file):
    global current_date
    def get_cutoff_date():
        global current_date
        if config["cutoffDate"] == "":
            return current_date
            # datetime.strptime(current_date.strftime("%Y-%m-%d 00:00:00"), "%Y-%m-%d %H:%M:%S")
        else:
            datetime.strptime(config["cutoffDate"], "%Y-%m-%d %H:%M:%S")

    if cutoff_date == "":
        cutoff_date = get_cutoff_date().strftime("%Y-%m-%d %H:%M:%S")

    f = open(config_file, )
    config1 = json.load(f)
    f.close()

    config1["newCutoffDate"] = cutoff_date
    with open(config_file, 'w', encoding='utf-8') as file:
        json.dump(config1, file, indent=4, ensure_ascii=False)

@task
def single_task():
    print(f"single_task")

def get_load_wwi(idx_process, tables):
    return PapermillOperator(
        task_id=f"load_wwi{idx_process}",
        input_nb=f"{load_process_directory}/load_wwi.ipynb",
        output_nb=f"{load_process_directory}/outputs/load_wwi{idx_process}_{config["newCutoffDate"]}_{current_date.strftime("%Y-%m-%d %H:%M:%S")}_output.ipynb",
        parameters={
            "fromNotebook": False,
            "configFile": load_config_file,
            "newCutoffDate": config["newCutoffDate"],
            "tables": tables,
            "sqlUtilFilePath": f"{load_process_directory}/modules/sql_utilities.py",
            "script_directory": f"{load_process_directory}/",
            "archivePath": load_process_directory,
            "isInsertLoadHistoryDate": False
        }
    )

def get_load_wwi_insert_load_history_date():
    return PapermillOperator(
        task_id=f"load_wwi_insert_load_history_date",
        input_nb=f"{load_process_directory}/load_wwi.ipynb",
        output_nb=f"{load_process_directory}/outputs/load_wwi_insert_load_history_date_{current_date.strftime("%Y-%m-%d %H:%M:%S")}_output.ipynb",
        parameters={
            "fromNotebook": False,
            "configFile": load_config_file,
            "newCutoffDate": config["newCutoffDate"],
            "tables": [],
            "sqlUtilFilePath": f"{load_process_directory}/modules/sql_utilities.py",
            "script_directory": f"{load_process_directory}/",
            "archivePath": load_process_directory,
            "isInsertLoadHistoryDate": True
        }
    )

def get_load_wwi_processes():
    load_wwi = []
    idx = 0
    tables = []
    idx_process = 1
    idx_table = 0

    if no_of_load_tables_per_process == 0:
        print(f"tables in load_wwi{idx_process}: {load_config["tables"]}")
        load_wwi.append(get_load_wwi(idx_process, load_config["tables"]))
    else:
        for table in load_config["tables"]:
            tables.append(table)
            idx = idx + 1
            idx_table = idx_table + 1

            if idx == no_of_load_tables_per_process or idx_table == len(load_config["tables"]):
                print(f"tables in load_wwi{idx_process}: {tables}")
                load_wwi.append(get_load_wwi(idx_process, tables))
                idx = 0
                idx_process = idx_process + 1
                tables = []

    return load_wwi

def get_warehouse_wwi(idx_process, tables_name, tables):
    dimension_tables = []
    fact_tables = []

    if tables_name == "dimensionTables":
        dimension_tables = tables
    else:
        fact_tables = tables

    return PapermillOperator(
        task_id=f"warehouse_wwi_{tables_name}{idx_process}",
        input_nb=f"{warehouse_process_directory}/warehouse_wwi.ipynb",
        output_nb=f"{warehouse_process_directory}/outputs/warehouse_wwi{idx_process}_{config["newCutoffDate"]}_{current_date.strftime("%Y-%m-%d %H:%M:%S")}_output.ipynb",
        parameters={
            "fromNotebook": False,
            "loadConfigFile": load_config_file,
            "configFile": warehouse_config_file,
            "newCutoffDate": config["newCutoffDate"],
            "dimension_tables": dimension_tables,
            "fact_tables": fact_tables,
            "sqlUtilFilePath": f"{warehouse_process_directory}/modules/sql_utilities.py",
            "archivePath": warehouse_process_directory,
            "script_directory": ""f"{warehouse_process_directory}/",
            "isInsertWarehouseHistoryDate": False
        }
    )

def get_warehouse_wwi_insert_warehouse_history_date():
    return PapermillOperator(
        task_id=f"warehouse_wwi_insert_warehouse_history_date",
        input_nb=f"{warehouse_process_directory}/warehouse_wwi.ipynb",
        output_nb=f"{warehouse_process_directory}/outputs/warehouse_wwi_insert_warehouse_history_date_{current_date.strftime("%Y-%m-%d %H:%M:%S")}_output.ipynb",
        parameters={
            "fromNotebook": False,
            "loadConfigFile": load_config_file,
            "configFile": warehouse_config_file,
            "newCutoffDate": config["newCutoffDate"],
            "dimension_tables": [],
            "fact_tables": [],
            "sqlUtilFilePath": f"{warehouse_process_directory}/modules/sql_utilities.py",
            "archivePath": warehouse_process_directory,
            "script_directory": ""f"{warehouse_process_directory}/",
            "isInsertWarehouseHistoryDate": True
        }
    )

def get_warehouse_wwi_processes(tables_name, no_tables_per_process):
    warehouse_wwi = []
    idx = 0
    tables = []
    idx_process = 1
    idx_table = 0

    if no_tables_per_process == 0:
        print(f"tables in warehouse_wwi_{tables_name}{idx_process}: {warehouse_config[tables_name]}")
        warehouse_wwi.append(get_warehouse_wwi(idx_process, tables_name, warehouse_config[tables_name]))
    else:
        for table in warehouse_config[tables_name]:
            tables.append(table)
            idx = idx + 1
            idx_table = idx_table + 1

            if idx == no_tables_per_process or idx_table == len(warehouse_config[tables_name]):
                print(f"tables in warehouse_wwi_{tables_name}{idx_process}: {tables}")
                warehouse_wwi.append(get_warehouse_wwi(idx_process, tables_name, tables))
                idx = 0
                idx_process = idx_process + 1
                tables = []

    return warehouse_wwi

@task
def get_load_wwi_copy_files():
    if not os.path.isdir(load_directory):
        raise NotADirectoryError(f"Source directory '{load_directory}' does not exist or is not a directory.")
    shutil.copytree(load_directory, load_process_directory, dirs_exist_ok=True)
    shutil.copy2(load_config_file, f"{load_process_directory}/load_wwi.json")
    os.makedirs(f"{load_process_directory}/modules", exist_ok=True)
    os.makedirs(f"{load_process_directory}/outputs", exist_ok=True)
    shutil.copy2(sql_utilities_file, f"{load_process_directory}/modules/sql_utilities.py")

@task
def get_warehouse_wwi_copy_files():
    if not os.path.isdir(warehouse_directory):
        raise NotADirectoryError(f"Source directory '{warehouse_directory}' does not exist or is not a directory.")
    shutil.copytree(warehouse_directory, warehouse_process_directory, dirs_exist_ok=True)
    shutil.copy2(warehouse_config_file, f"{warehouse_process_directory}/warehouse_wwi.json")
    os.makedirs(f"{warehouse_process_directory}/modules", exist_ok=True)
    os.makedirs(f"{warehouse_process_directory}/outputs", exist_ok=True)
    shutil.copy2(sql_utilities_file, f"{warehouse_process_directory}/modules/sql_utilities.py")

with DAG(
    dag_id="process_wwi",
    default_args=default_args,
    dagrun_timeout=timedelta(minutes=60)
) as dag:
    new_cutoff_date = set_cutoff_date("set_cutoff_date", cutoff_date, config_file)
    copy_load_files = get_load_wwi_copy_files()
    single_task_placeholder = single_task() 
    load_wwi = get_load_wwi_processes()
    copy_warehouse_files = get_warehouse_wwi_copy_files()
    warehouse_wwi_dimension = get_warehouse_wwi_processes("dimensionTables", no_of_warehouse_dimension_tables_per_process)
    warehouse_wwi_fact = get_warehouse_wwi_processes("factTables", no_of_warehouse_fact_tables_per_process)
    
    (
        new_cutoff_date 
        >>
        copy_load_files
        >> 
        load_wwi 
        >>
        copy_warehouse_files
        >>  
        warehouse_wwi_dimension 
        >> 
        single_task_placeholder  
        >> 
        warehouse_wwi_fact
    )
    