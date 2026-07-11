import os
import json
import shutil
import requests
import zipfile
import io
from airflow.operators.trigger_dagrun import TriggerDagRunOperator

from airflow.sdk import task
from datetime import timedelta, datetime
from airflow.models import DAG
from airflow.providers.papermill.operators.papermill import PapermillOperator

path = os.getcwd()
config_file = f"{path}/dags/process_wwi_v3.json"

f = open(config_file,)
config = json.load(f)
f.close()

cutoff_date = config["cutoffDate"]
no_of_workers = config["noOfWorkers"]
current_date = datetime.strptime(datetime.now().strftime("%Y-%m-%d 00:00:00"), "%Y-%m-%d %H:%M:%S")
load_directories = config["loadDirectories"]
warehouse_directories = config["warehouseDirectories"]
copy_files_type = config["copyFilesType"]
release_github_repo = ""
release_github_branch = ""
github_token = "" 
load_config_env = config["loadConfigEnvironment"]
warehouse_config_env = config["warehouseConfigEnvironment"]
version = config["version"]
raise_error_when_new_version_found = config["raiseErrorWhenNewVersionFound"]

if config["copyFilesType"]["type"] == "github":
    release_github_repo = config["copyFilesType"]["repo"]
    release_github_branch = config["copyFilesType"]["branch"]
    
    with open(f"{path}{config["copyFilesType"]["tokenPath"]}", 'r', encoding='utf-8') as file:
        github_token = file.read()

print(f"cutoff_date: {cutoff_date}")
print(f"no_of_workers: {no_of_workers}")
print(f"current_date: {current_date}")
print(f"load_directories: {load_directories}")
print(f"warehouse_directories: {warehouse_directories}")
print(f"load_config_env: {load_config_env}")
print(f"warehouse_config_env: {warehouse_config_env}")
print(f"release_github_repo: {release_github_repo}")
print(f"release_github_branch: {release_github_branch}")
print(f"github_token: {github_token}")
print(f"version: {version}")
print(f"raise_error_when_new_version_found: {raise_error_when_new_version_found}")

@task
def single_task():
    print(f"single_task")

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

def copy_if_not_exists(source, destination):
    if not os.path.exists(destination):
        return shutil.copy2(source, destination)
    
    return source

def copy_local_files(process_directory):
    archive_folder = f"{copy_files_type["type"]}_{config["newCutoffDate"].replace(":", "")}"
    
    for directory in process_directory["copy"]:
        shutil.copytree(
            f"{path}{directory["source"]}", 
            f"{path}{directory["destination"]}".replace("{archive_folder}", archive_folder), 
            dirs_exist_ok=True
        )

    for directory in process_directory["create"]:
        os.makedirs(
            f"{path}{directory["destination"]}".replace("{archive_folder}", archive_folder), 
            exist_ok=True
        )

    for file in process_directory["replaceFiles"]:
        shutil.copy2(
            f"{path}{file["source"]}".replace("{archive_folder}", archive_folder).replace("{environment}", load_config_env), 
            f"{path}{file["destination"]}".replace("{archive_folder}", archive_folder).replace("{environment}", load_config_env)
        )

def copy_github_file(zip_bytes, folder_path, output_dir):
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

def get_github_json(zip_bytes, file_path):
    """Extract only the specified folder from the repo ZIP."""
    try:

        with zipfile.ZipFile(zip_bytes) as z:
            # GitHub ZIPs have a top-level folder like repo-branch/
            top_level_dir = z.namelist()[0].split("/")[0]
            target_prefix = f"{top_level_dir}/{file_path}"

            with z.open(target_prefix) as file:
                content = file.read().decode('utf-8')
                return json.loads(content)
    
    except Exception as e:
        raise Exception(e)
        
def copy_github_files(zip_bytes, process_directory, tag_name):
    archive_folder = f"{copy_files_type["type"]}_{tag_name}"
    
    for directory in process_directory["copy"]:
        if os.path.isdir(f"{path}{directory["destination"]}".replace("{archive_folder}", archive_folder)) == False:
            print(f"Copied {directory["source"]} to {f"{path}{directory["destination"]}".replace("{archive_folder}", archive_folder)}.")
            copy_github_file(zip_bytes, directory["source"], f"{path}{directory["destination"]}".replace("{archive_folder}", archive_folder))
        else:
            print(f"{f"{path}{directory["destination"]}".replace("{archive_folder}", archive_folder)} already exists.")

    for directory in process_directory["create"]:
        os.makedirs(
            f"{path}{directory["destination"]}".replace("{archive_folder}", archive_folder), 
            exist_ok=True
        )

    for file in process_directory["replaceFiles"]:
        shutil.copy2(
            f"{path}{file["source"]}".replace("{archive_folder}", archive_folder).replace("{environment}", load_config_env), 
            f"{path}{file["destination"]}".replace("{archive_folder}", archive_folder).replace("{environment}", load_config_env)
        )

# def extract_folder_from_zip(zip_bytes, folder_path, output_dir):
#     """Extract only the specified folder from the repo ZIP."""
#     with zipfile.ZipFile(zip_bytes) as z:
#         # GitHub ZIPs have a top-level folder like repo-branch/
#         top_level_dir = z.namelist()[0].split("/")[0]
#         target_prefix = f"{top_level_dir}/{folder_path.strip('/')}/"

#         found = False
#         for member in z.namelist():
#             if member.startswith(target_prefix):
#                 found = True
#                 relative_path = os.path.relpath(member, target_prefix)
#                 if relative_path == ".":
#                     continue  # Skip the folder itself
#                 target_path = os.path.join(output_dir, relative_path)
#                 if member.endswith("/"):
#                     os.makedirs(target_path, exist_ok=True)
#                 else:
#                     os.makedirs(os.path.dirname(target_path), exist_ok=True)
#                     with z.open(member) as source, open(target_path, "wb") as target:
#                         shutil.copyfileobj(source, target)

#         if not found:
#             raise Exception(f"Folder '{folder_path}' not found in ZIP.")

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

def get_latest_release_by_branch():
    """
    Get the latest GitHub release for a specific branch using the REST API.
    
    :return: Dict with release info or None if not found
    """
    
    headers = {
        "Authorization": f"token {github_token}",
        "Accept": "application/vnd.github+json"
    }

    owner = config["copyFilesType"]["owner"]
    repo = config["copyFilesType"]["repo"]
    branch = config["copyFilesType"]["branch"]
    url = f"https://api.github.com/repos/{owner}/{repo}/releases"

    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        releases = response.json()

        branch_releases = [
            r for r in releases if r.get("target_commitish") == branch
        ]

        if not branch_releases:
            raise Exception(f"No release found in branch {branch}")

        branch_releases.sort(key=lambda r: r.get("created_at", ""), reverse=True)
        return branch_releases[0]

    except Exception as e:
        raise Exception(e)

@task 
def get_process_wwi_files():
    print(f"copy files type: {config["copyFilesType"]}")
    if config["copyFilesType"]["type"] == "local":
        copy_local_files(load_directories)
        copy_local_files(warehouse_directories)
    elif config["copyFilesType"]["type"] == "github":
        latest_release = get_latest_release_by_branch()
        zip_bytes = download_repo_zip(
            config["copyFilesType"]["owner"], 
            config["copyFilesType"]["repo"], 
            config["copyFilesType"]["branch"], 
            github_token,
            latest_release["tag_name"]
        )

        archive_folder = f"{copy_files_type["type"]}_{latest_release["tag_name"]}"
        process_config = get_github_json(zip_bytes, f"/dags/process_wwi_archive/{archive_folder}/dags/process_wwi_v3.py"), 
        
        copy_github_files(zip_bytes, load_directories, latest_release["tag_name"])
        copy_github_files(zip_bytes, warehouse_directories, latest_release["tag_name"])

        # extract_folder_from_zip(zip_bytes, config["loadDirectory"], github_load_process_directory)

        # if os.path.isdir(github_load_process_directory) == False:
        
        # github_load_process_directory = f"{path}{config["loadProcessDirectory"]}/{latest_release["tag_name"]}"
        # github_load_process_config_file = f"{github_load_process_directory}/load_wwi_{load_config_env}.json"
        # github_warehouse_process_directory = f"{path}{config["warehouseProcessDirectory"]}/{latest_release["tag_name"]}"
        # github_warehouse_process_config_file = f"{github_warehouse_process_directory}/warehouse_wwi_{warehouse_config_env}.json"

        # f = open(config_file, )
        # config1 = json.load(f)
        # f.close()

        # config1["githubLoadProcessDirectory"] = github_load_process_directory
        # config1["githubWarehouseProcessDirectory"] = github_warehouse_process_directory
        # config1["githubReleaseTag"] = latest_release["tag_name"]
        
        # with open(config_file, 'w', encoding='utf-8') as file:
        #     json.dump(config1, file, indent=4, ensure_ascii=False)
        
        # # create load process directory
        # if os.path.isdir(github_load_process_directory) == False:
        #     print(f"Copying load process files to {github_load_process_directory}.")
        #     extract_folder_from_zip(zip_bytes, config["loadDirectory"], github_load_process_directory)
        #     os.makedirs(f"{github_load_process_directory}/modules", exist_ok=True)
        #     os.makedirs(f"{github_load_process_directory}/outputs", exist_ok=True)
        #     extract_folder_from_zip(zip_bytes, config["modulesDirectory"], f"{github_load_process_directory}/modules")
        #     shutil.copy2(github_load_process_config_file, f"{github_load_process_directory}/load_wwi.json")
        # else:
        #     shutil.copy2(github_load_process_config_file, f"{github_load_process_directory}/load_wwi.json")
        #     print(f"Load directory {github_load_process_directory} already exists.")
        
        # # create warehouse process directory
        # if os.path.isdir(github_warehouse_process_directory) == False:
        #     print(f"Copying warehouse process files to {github_warehouse_process_directory}.")
        #     extract_folder_from_zip(zip_bytes, config["warehouseDirectory"], github_warehouse_process_directory)
        #     os.makedirs(f"{github_warehouse_process_directory}/modules", exist_ok=True)
        #     os.makedirs(f"{github_warehouse_process_directory}/outputs", exist_ok=True)
        #     extract_folder_from_zip(zip_bytes, config["modulesDirectory"], f"{github_warehouse_process_directory}/modules")
        #     shutil.copy2(github_warehouse_process_config_file, f"{github_warehouse_process_directory}/warehouse_wwi.json")
        # else:
        #     shutil.copy2(github_warehouse_process_config_file, f"{github_warehouse_process_directory}/warehouse_wwi.json")
        #     print(f"Warehouse directory {github_warehouse_process_directory} already exists.")

default_args = {
    "owner": "Airflow",
    "start_date": datetime(2025, 1, 1)
}

with DAG(
    dag_id="process_wwi_v3",
    default_args=default_args,
    dagrun_timeout=timedelta(minutes=60)
) as dag:
    new_cutoff_date = set_cutoff_date("set_cutoff_date", cutoff_date, config_file)
    copy_process_wwi_files = get_process_wwi_files()
    
    (
        new_cutoff_date
        >>
        copy_process_wwi_files
    )