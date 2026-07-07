import os
import json
import shutil
import requests
import zipfile
import io

from airflow.sdk import task
from datetime import timedelta, datetime
from airflow.models import DAG
from airflow.providers.papermill.operators.papermill import PapermillOperator

def get_latest_tag_from_branch(token):
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github+json"
    }

    try:
        owner = config["copyFilesType"]["owner"]
        repo = config["copyFilesType"]["repo"]
        branch = config["copyFilesType"]["branch"]
        
        # 1. Get latest commit SHA from branch
        branch_url = f"https://api.github.com/repos/{owner}/{repo}/branches/{branch}"
        branch_resp = requests.get(branch_url, headers=headers)
        branch_resp.raise_for_status()
        latest_commit_sha = branch_resp.json()["commit"]["sha"]

        # 2. Get all tags
        tags_url = f"https://api.github.com/repos/{owner}/{repo}/tags"
        tags_resp = requests.get(tags_url, headers=headers)
        tags_resp.raise_for_status()
        tags = tags_resp.json()

        latest_tag = list(filter(lambda tag: tag["commit"]["sha"] == latest_commit_sha, tags))

        if len(latest_tag) > 0:
            return latest_tag[0]["name"]
        else:
            raise Exception(f"Latest commit is not associated to tag in {repo} branch {branch}.")

    except Exception as e:
        raise Exception(e)

path = os.getcwd()
config_file = f"{path}/dags/process_wwi_v2.json"

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
release_github_repo = ""
release_github_branch = ""
release_github_tag = ""
github_token = ""
if config["copyFilesType"]["type"] == "github":
    release_github_repo = config["copyFilesType"]["repo"]
    release_github_branch = config["copyFilesType"]["branch"]
    with open(f"{path}/{config["copyFilesType"]["tokenPath"]}", 'r', encoding='utf-8') as file:
        github_token = file.read()
    release_github_tag = get_latest_tag_from_branch(github_token)

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
print(f"release_github_repo: {release_github_repo}")
print(f"release_github_branch: {release_github_branch}")
print(f"github_token: {github_token}")

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
    final_load_process_directory = load_process_directory
    
    if config["copyFilesType"]["type"] == "github":
        final_load_process_directory = config["githubLoadProcessDirectory"]
    
    return PapermillOperator(
        task_id=f"load_wwi{idx_process}",
        input_nb=f"{final_load_process_directory}/load_wwi.ipynb",
        output_nb=f"{final_load_process_directory}/outputs/load_wwi{idx_process}_{config["newCutoffDate"]}_{current_date.strftime("%Y-%m-%d %H:%M:%S")}_output.ipynb",
        parameters={
            "fromNotebook": False,
            "configFile": load_config_file,
            "newCutoffDate": config["newCutoffDate"],
            "tables": tables,
            "sqlUtilFilePath": f"{final_load_process_directory}/modules/sql_utilities.py",
            "script_directory": f"{final_load_process_directory}/",
            "archivePath": final_load_process_directory,
            "isInsertLoadHistoryDate": False,
            "release_github_repo": release_github_repo,
            "release_github_branch": release_github_branch,
            "release_github_tag": release_github_tag
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

def get_load_wwi_copy_files():
    if not os.path.isdir(load_directory):
        raise NotADirectoryError(f"Source directory '{load_directory}' does not exist or is not a directory.")
    shutil.copytree(load_directory, load_process_directory, dirs_exist_ok=True)
    shutil.copy2(load_config_file, f"{load_process_directory}/load_wwi.json")
    os.makedirs(f"{load_process_directory}/modules", exist_ok=True)
    os.makedirs(f"{load_process_directory}/outputs", exist_ok=True)
    shutil.copy2(sql_utilities_file, f"{load_process_directory}/modules/sql_utilities.py")

def get_warehouse_wwi_copy_files():
    if not os.path.isdir(warehouse_directory):
        raise NotADirectoryError(f"Source directory '{warehouse_directory}' does not exist or is not a directory.")
    shutil.copytree(warehouse_directory, warehouse_process_directory, dirs_exist_ok=True)
    shutil.copy2(warehouse_config_file, f"{warehouse_process_directory}/warehouse_wwi.json")
    os.makedirs(f"{warehouse_process_directory}/modules", exist_ok=True)
    os.makedirs(f"{warehouse_process_directory}/outputs", exist_ok=True)
    shutil.copy2(sql_utilities_file, f"{warehouse_process_directory}/modules/sql_utilities.py")

def extract_folder_from_zip(zip_bytes, folder_path, output_dir):
    """Extract only the specified folder from the repo ZIP."""
    with zipfile.ZipFile(zip_bytes) as z:
        # GitHub ZIPs have a top-level folder like repo-branch/
        top_level_dir = z.namelist()[0].split("/")[0]
        target_prefix = f"{top_level_dir}/{folder_path.strip('/')}/"

        found = False
        for member in z.namelist():
            if member.startswith(target_prefix):
                found = True
                relative_path = os.path.relpath(member, target_prefix)
                if relative_path == ".":
                    continue  # Skip the folder itself
                target_path = os.path.join(output_dir, relative_path)
                if member.endswith("/"):
                    os.makedirs(target_path, exist_ok=True)
                else:
                    os.makedirs(os.path.dirname(target_path), exist_ok=True)
                    with z.open(member) as source, open(target_path, "wb") as target:
                        shutil.copyfileobj(source, target)

        if not found:
            raise Exception(f"Folder '{folder_path}' not found in ZIP.")

def download_repo_zip(owner, repo, branch, token=None, tag=None):
    """Download the entire repo as a ZIP and return a BytesIO object."""
    if tag:
        url = f"https://github.com/{owner}/{repo}/archive/refs/tags/{tag}.zip"
    else:
        url = f"https://github.com/{owner}/{repo}/archive/refs/heads/{branch}.zip"
    
    headers = {}
    
    if token:
        headers["Authorization"] = f"token {token}"

    print(f"Downloading ZIP from {url} ...")
    r = requests.get(url, headers=headers, stream=True)
    if r.status_code != 200:
        raise Exception(f"Failed to download ZIP: {r.status_code} {r.text}")
    return io.BytesIO(r.content)


# def create_replace_branch(token):
#     base_url = f"https://api.github.com/repos/{config["copyFilesType"]["owner"]}/{config["copyFilesType"]["repo"]}"
#     headers = {
#         "Authorization": f"token {token}",
#         "Accept": "application/vnd.github+json"
#     }

#     def get_branch_sha(branch):
#         """Get the latest commit SHA of a branch."""
#         url = f"{base_url}/git/ref/heads/{branch}"
#         resp = requests.get(url, headers=headers)
#         if resp.status_code == 200:
#             return resp.json()["object"]["sha"]
#         elif resp.status_code == 404:
#             return None
#         else:
#             raise Exception(f"Error fetching branch {branch}: {resp.text}")
        
#     def create_branch(branch, sha):
#         """Create a new branch from a given commit SHA."""
#         url = f"{base_url}/git/refs"
#         payload = {
#             "ref": f"refs/heads/{branch}",
#             "sha": sha
#         }
#         resp = requests.post(url, json=payload, headers=headers)
#         if resp.status_code == 201:
#             print(f"✅ Branch '{branch}' created successfully.")
#         elif resp.status_code == 422 and "Reference already exists" in resp.text:
#             print(f"⚠️ Branch '{branch}' already exists.")
#         else:
#             raise Exception(f"Error creating branch: {resp.text}")

#     def update_branch(branch, sha):
#         """Force update an existing branch to point to a new commit SHA."""
#         url = f"{base_url}/git/refs/heads/{branch}"
#         payload = {
#             "sha": sha,
#             "force": True
#         }
#         resp = requests.patch(url, json=payload, headers=headers)
#         if resp.status_code == 200:
#             print(f"✅ Branch '{branch}' updated to new commit.")
#         else:
#             raise Exception(f"❌ Error updating branch: {resp.text}")        

#     source_sha = get_branch_sha(config["copyFilesType"]["branch"])
    
#     if not source_sha:
#         raise Exception(f"Source branch does not exists.")
    
#     target_branch = release_github_branch
#     target_sha = get_branch_sha(target_branch)

#     if target_sha:
#         update_branch(target_branch, source_sha)
#     else:
#         create_branch(target_branch, source_sha)

@task 
def get_process_wwi_files():
    print(f"copy files type: {config["copyFilesType"]}")
    if config["copyFilesType"]["type"] == "local":
        get_load_wwi_copy_files()
        get_warehouse_wwi_copy_files()
    elif config["copyFilesType"]["type"] == "github":
        zip_bytes = download_repo_zip(
            config["copyFilesType"]["owner"], 
            config["copyFilesType"]["repo"], 
            config["copyFilesType"]["branch"], 
            github_token,
            release_github_tag
        )
        github_load_process_directory = f"{path}{config["loadProcessDirectory"]}/{release_github_tag}"
        f = open(config_file, )
        config1 = json.load(f)
        f.close()

        config1["githubLoadProcessDirectory"] = github_load_process_directory
        with open(config_file, 'w', encoding='utf-8') as file:
            json.dump(config1, file, indent=4, ensure_ascii=False)
        
        extract_folder_from_zip(zip_bytes, config["githubLoadDirectory"], github_load_process_directory)
        os.makedirs(f"{github_load_process_directory}/modules", exist_ok=True)
        os.makedirs(f"{github_load_process_directory}/outputs", exist_ok=True)
        extract_folder_from_zip(zip_bytes, config["githubModulesDirectory"], f"{github_load_process_directory}/modules")
        shutil.copy2(load_config_file, f"{github_load_process_directory}/load_wwi_{cutoff_date.replace("-", "").replace(":", "")}.json")
        # extract_folder_from_zip(zip_bytes, config["githubWarehouseDirectory"], warehouse_process_directory)
        
        # create_replace_branch(token)

with DAG(
    dag_id="process_wwi_v2",
    default_args=default_args,
    dagrun_timeout=timedelta(minutes=60)
) as dag:
    new_cutoff_date = set_cutoff_date("set_cutoff_date", cutoff_date, config_file)
    copy_process_wwi_files = get_process_wwi_files()
    # single_task_placeholder = single_task() 
    load_wwi = get_load_wwi_processes()
    
    # warehouse_wwi_dimension = get_warehouse_wwi_processes("dimensionTables", no_of_warehouse_dimension_tables_per_process)
    # warehouse_wwi_fact = get_warehouse_wwi_processes("factTables", no_of_warehouse_fact_tables_per_process)
    
    (
        new_cutoff_date 
        >>
        copy_process_wwi_files
        >> 
        load_wwi 
        # >>  
        # warehouse_wwi_dimension 
        # >> 
        # single_task_placeholder  
        # >> 
        # warehouse_wwi_fact
    )
    