import os
import json

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
current_date = datetime.now()

default_args = {
    "owner": "Airflow",
    "start_date": datetime(2025, 1, 1)
}

@task
def set_cutoff_date(name: str, cutoff_date, config_file):
    def get_cutoff_date():
        if config["cutoffDate"] == "":
            return current_date
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

with DAG(
    dag_id="process_wwi",
    default_args=default_args,
    dagrun_timeout=timedelta(minutes=60)
) as dag:
    new_cutoff_date = set_cutoff_date("set_cutoff_date", cutoff_date, config_file)

    load_wwi = PapermillOperator(
        task_id=f"load_wwi",
        input_nb=f"{path}/notebooks/load_wwi.ipynb",
        output_nb=f"{path}/notebooks/outputs/load_wwi_{current_date.strftime("%Y-%m-%d %H:%M:%S")}_output.ipynb",
        parameters={
            "fromNotebook": False,
            "configFile": load_config_file,
            "newCutoffDate": config["newCutoffDate"]
        }
    )

    warehouse_wwi = PapermillOperator(
        task_id=f"warehouse_wwi",
        input_nb=f"{path}/notebooks/warehouse_wwi.ipynb",
        output_nb=f"{path}/notebooks/outputs/warehouse_wwi_{current_date.strftime("%Y-%m-%d %H:%M:%S")}_output.ipynb",
        parameters={
            "fromNotebook": False,
            "loadConfigFile": load_config_file,
            "configFile": warehouse_config_file,
            "newCutoffDate": config["newCutoffDate"]
        }
    )

    new_cutoff_date >> load_wwi >> warehouse_wwi