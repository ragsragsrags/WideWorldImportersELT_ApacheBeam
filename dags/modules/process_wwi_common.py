import importlib
import json

from airflow.models import DAG
from airflow.providers.papermill.operators.papermill import PapermillOperator
from airflow.sdk import task
from datetime import timedelta, datetime


def get_load_wwi(dag_config, load_history_date_data, idx_process, current_date, no_of_workers, is_rollback = False, kernel_name = ""):
    if is_rollback == True:
        archive_path = load_history_date_data["ArchivePath"]
        cutoff_date = load_history_date_data["LoadDate"].strftime("%Y-%m-%d 00:00:00")

        return PapermillOperator(
            task_id=f"rollback_load_wwi{idx_process}",
            input_nb=f"{archive_path}/load_wwi.ipynb",
            output_nb=f"{archive_path}/outputs/rollback_load_wwi{idx_process}_{cutoff_date}_output.ipynb",
            parameters={
                "fromNotebook": False,
                "configFile": f"{archive_path}/load_wwi_{load_history_date_data["Environment"]}.json",
                "newCutoffDate": cutoff_date,
                "modules_directory": f"{archive_path}/modules",
                "archivePath": archive_path,
                "environment": load_history_date_data["Environment"],
                "is_rollback": is_rollback,
                "release_github_repo": load_history_date_data["ReleaseGithubRepo"],
                "release_github_branch": load_history_date_data["ReleaseGithubBranch"],
                "release_github_tag": load_history_date_data["ReleaseGithubTag"],
                "no_of_workers": no_of_workers,
                "process_id": idx_process
            },
            kernel_name=kernel_name
        )
    else:
        archive_path = dag_config["loadDirectories"]["archivePath"]

        return PapermillOperator(
            task_id=f"load_wwi{idx_process}",
            input_nb=f"{archive_path}/load_wwi.ipynb",
            output_nb=f"{archive_path}/outputs/load_wwi{idx_process}_{dag_config["newCutoffDate"]}_{current_date.strftime("%Y-%m-%d %H:%M:%S")}_output.ipynb",
            parameters={
                "fromNotebook": False,
                "configFile": dag_config["loadDirectories"]["configPath"],
                "newCutoffDate": dag_config["newCutoffDate"],
                "modules_directory": dag_config["loadDirectories"]["modulesPath"],
                "archivePath": archive_path,
                "environment": dag_config["environment"],
                "is_rollback": is_rollback,
                "release_github_repo": dag_config["copyFilesType"]["repo"],
                "release_github_branch": dag_config["copyFilesType"]["branch"],
                "release_github_tag": dag_config["releaseGithubTag"],
                "no_of_workers": dag_config["noOfWorkers"],
                "process_id": idx_process
            }
        )

def get_load_wwi_processes(dag_config, load_history_date_data, current_date, no_of_workers, is_rollback = False, kernel_name = ""):
    print(f"is_rollback: {is_rollback}")
    load_wwi = []

    for idx in range(no_of_workers):
        # print(idx)
        load_wwi.append(
            get_load_wwi(
                dag_config,
                load_history_date_data,
                idx + 1, 
                current_date, 
                no_of_workers, 
                is_rollback, 
                kernel_name
            )
        )

    return load_wwi

def get_warehouse_wwi(dag_config, load_history_date_data, warehouse_history_date_data, idx_process, table_type, current_date, no_of_workers, is_rollback = False, kernel_name = ""):
    if is_rollback == True:
        warehouse_archive_path = warehouse_history_date_data["ArchivePath"]
        cutoff_date = warehouse_history_date_data["LoadDate"].strftime("%Y-%m-%d 00:00:00")
        
        return PapermillOperator(
            task_id=f"rollback_warehouse_wwi_{table_type}{idx_process}",
            input_nb=f"{warehouse_archive_path}/warehouse_wwi.ipynb",
            output_nb=f"{warehouse_archive_path}/outputs/rollback_warehouse_wwi_{table_type}{idx_process}_{cutoff_date}_output.ipynb",
            parameters={
                "fromNotebook": False,
                "loadConfigFile": f"{load_history_date_data["ArchivePath"]}/load_wwi_{load_history_date_data["Environment"]}.json",
                "configFile": f"{warehouse_archive_path}/warehouse_wwi_{warehouse_history_date_data["Environment"]}.json",
                "newCutoffDate": cutoff_date,
                "modules_directory": f"{warehouse_archive_path}/modules",
                "archivePath": warehouse_archive_path,
                "environment": warehouse_history_date_data["Environment"],
                "is_rollback": is_rollback,
                "no_of_workers": no_of_workers,
                "process_id": idx_process
            },
            kernel_name=kernel_name
        )
    else:
        archive_path = dag_config["warehouseDirectories"]["archivePath"]
    
        return PapermillOperator(
            task_id=f"warehouse_wwi_{table_type}{idx_process}",
            input_nb=f"{archive_path}/warehouse_wwi.ipynb",
            output_nb=f"{archive_path}/outputs/warehouse_wwi{idx_process}_{dag_config["newCutoffDate"]}_{current_date.strftime("%Y-%m-%d %H:%M:%S")}_output.ipynb",
            parameters={
                "fromNotebook": False,
                "loadConfigFile": dag_config["loadDirectories"]["configPath"],
                "configFile": dag_config["warehouseDirectories"]["configPath"],
                "newCutoffDate": dag_config["newCutoffDate"],
                "modules_directory": dag_config["warehouseDirectories"]["modulesPath"],
                "archivePath": archive_path,
                "environment": dag_config["environment"],
                "release_github_repo": dag_config["environment"],
                "release_github_branch": dag_config["copyFilesType"]["branch"],
                "release_github_tag": dag_config["releaseGithubTag"],
                "is_rollback": is_rollback,
                "no_of_workers": dag_config["noOfWorkers"],
                "process_id": idx_process,
                "table_type": table_type
            }
        )

def get_warehouse_wwi_processes(dag_config, load_history_date_data, warehouse_history_date_data, table_type, current_date, no_of_workers, is_rollback = False, kernel_name = ""):
    warehouse_wwi = []

    for idx in range(no_of_workers):
        warehouse_wwi.append(
            get_warehouse_wwi(
                dag_config,
                load_history_date_data, 
                warehouse_history_date_data, 
                idx + 1, 
                table_type, 
                current_date, 
                no_of_workers,
                is_rollback,
                kernel_name
            )
        )

    return warehouse_wwi

def create_process_wwi_rollback_dag(load_history_date_data, warehouse_history_date_data, no_of_workers, cutoff_date, current_date, kernel_name):
    default_args = {
        "owner": "Airflow",
        "start_date": datetime(2025, 1, 1)
    }

    @task
    def single_task():
        print(f"single_task")

    with DAG(
        dag_id="process_wwi_rollback_v2",
        default_args=default_args,
        dagrun_timeout=timedelta(minutes=60)
    ) as dag:
        single_task_placeholder = single_task() 
        single_task_placeholder2 = single_task()
        rollback_load_wwi = get_load_wwi_processes(
            None,
            load_history_date_data, 
            current_date, 
            no_of_workers, 
            True, 
            kernel_name
        ) 
        rollback_warehouse_wwi_dimension = get_warehouse_wwi_processes(
            None,
            load_history_date_data, 
            warehouse_history_date_data, 
            "dimension", 
            current_date, 
            no_of_workers, 
            True, 
            kernel_name
        )
        rollback_warehouse_wwi_fact = get_warehouse_wwi_processes(
            None,
            load_history_date_data, 
            warehouse_history_date_data, 
            "fact", 
            current_date, 
            no_of_workers, 
            True, 
            kernel_name
        )

        (
            rollback_load_wwi
            >>
            single_task_placeholder
            >>
            rollback_warehouse_wwi_dimension
            >>
            single_task_placeholder2
            >>
            rollback_warehouse_wwi_fact
        )

    return dag