import os
import json
import importlib
import modules.sql_utilities as sql_utils

from pathlib import Path
from datetime import timedelta, datetime
from airflow.sdk import task
from airflow.models import DAG

path = os.getcwd()
config_file = f"{path}/dags/process_wwi_rollback.json"

f = open(config_file,)
config = json.load(f)
f.close()

cutoff_date = config["cutoffDate"]
kernel_name = config["kernelName"]
gcp_credential = config["gcpCredential"]
no_of_workers = config["noOfWorkers"]
current_date = datetime.strptime(datetime.now().strftime("%Y-%m-%d 00:00:00"), "%Y-%m-%d %H:%M:%S")

print(f"cutoff_date: {cutoff_date}")
print(f"kernel_name: {kernel_name}")
print(f"gcp_credential: {gcp_credential}")
print(f"no_of_workers: {no_of_workers}")

os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = gcp_credential

def get_load_history_date_by_loaddate(new_cutoff_date):
    sql = sql_utils.get_sql_from_script(
        path=f"{config["loadHistoryDate"]["loadLoadHistoryDateTable"]}", 
        values=[
            { "name": "Schema", "value": config["loadHistoryDate"]["schema"] },
            { "name": "Table", "value": config["loadHistoryDate"]["table"] },
            { "name": "Database", "value": config["destination"]["database"] },
            { "name": "LoadDate", "value": new_cutoff_date }
        ], 
        tables=[],
        directory=""
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
        path=f"{config["warehouseHistoryDate"]["loadWarehouseHistoryDateTable"]}", 
        values=[
            { "name": "Schema", "value": config["warehouseHistoryDate"]["schema"] },
            { "name": "Table", "value": config["warehouseHistoryDate"]["table"] },
            { "name": "Database", "value": config["destination"]["database"] },
            { "name": "LoadDate", "value": new_cutoff_date }
        ], 
        tables=[],
        directory=f""
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

if len(load_history_date_data) == 0:
    load_history_date_data = None
else:
    load_history_date_data = load_history_date_data[0]

if len(warehouse_history_date_data) == 0:
    warehouse_history_date_data = None
else:
    warehouse_history_date_data = warehouse_history_date_data[0]

print(f"load_history_date_data: {load_history_date_data}")
print(f"warehouse_history_date_data: {warehouse_history_date_data}")

@task
def load_date_not_found_task():
    raise Exception(f"Cutoff date {cutoff_date} not found in Load or Warehouse load dates.")

if load_history_date_data is None or warehouse_history_date_data is None:
    default_args = {
        "owner": "Airflow",
        "start_date": datetime(2025, 1, 1)
    }

    with DAG(
        dag_id="process_wwi_rollback",
        default_args=default_args,
        dagrun_timeout=timedelta(minutes=60)
    ) as dag:
        (
            load_date_not_found_task()
        )
else:
    process_wwi_common_path = f"{str((Path(load_history_date_data["ArchivePath"])).parent)}/modules/process_wwi_common.py"
    print(f"process_wwi_common_path: {process_wwi_common_path}")

    spec_process_wwi_common = importlib.util.spec_from_file_location("process_wwi_common", process_wwi_common_path)
    process_wwi_common = importlib.util.module_from_spec(spec_process_wwi_common)
    spec_process_wwi_common.loader.exec_module(process_wwi_common)

    process_wwi_common.create_process_wwi_rollback_dag(
        load_history_date_data, 
        warehouse_history_date_data, 
        no_of_workers, 
        cutoff_date, 
        current_date, 
        kernel_name
    )