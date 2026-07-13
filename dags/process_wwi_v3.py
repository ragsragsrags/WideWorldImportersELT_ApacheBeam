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
release_github_environment = ""
github_token = "" 
environment = config["environment"]
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
print(f"environment: {environment}")
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

def copy_local_files(process_directory, archive_folder):
    # archive_folder = f"{copy_files_type["type"]}_{config["newCutoffDate"].replace(":", "")}"
    
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
            f"{path}{file["source"]}".replace("{archive_folder}", archive_folder).replace("{environment}", environment), 
            f"{path}{file["destination"]}".replace("{archive_folder}", archive_folder).replace("{environment}", environment)
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
            target_prefix = f"{top_level_dir}/{file_path.strip('/')}"

            with z.open(target_prefix) as file:
                content = file.read().decode('utf-8')
                return json.loads(content)
    
    except Exception as e:
        raise Exception(e)
        
def copy_github_files(zip_bytes, process_directory, archive_folder):
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
            f"{path}{file["source"]}".replace("{archive_folder}", archive_folder).replace("{environment}", environment), 
            f"{path}{file["destination"]}".replace("{archive_folder}", archive_folder).replace("{environment}", environment)
        )

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

def get_latest_directory(base_path, prefix):
    """
    Returns the most recently modified directory in base_path
    that starts with the given prefix.
    """
    try:
        from pathlib import Path

        base = Path(base_path)

        # Validate base path
        if not base.exists() or not base.is_dir():
            raise FileNotFoundError(f"Base path '{base_path}' does not exist or is not a directory.")

        # Filter directories with the given prefix
        matching_dirs = [
            d for d in base.iterdir()
            if d.is_dir() and d.name.startswith(prefix)
        ]

        if not matching_dirs:
            raise FileNotFoundError(f"No directories found with prefix '{prefix}' in '{base_path}'.")

        # Find the latest directory by modification time
        latest_dir = max(matching_dirs, key=lambda d: d.stat().st_mtime)
        return latest_dir

    except Exception as e:
        print(f"Error: {e}")

def save_bytesio_to_file(bytes_io_obj, file_path):
    """
    Save a BytesIO object to a file on disk.

    :param bytes_io_obj: io.BytesIO object containing binary data
    :param file_path: Path where the file will be saved
    """
    try:
        # Move cursor to the start of the BytesIO buffer
        bytes_io_obj.seek(0)

        # Open file in binary write mode and write the buffer
        with open(file_path, 'wb') as f:
            # Using getbuffer() avoids unnecessary copying
            f.write(bytes_io_obj.getbuffer())

        print(f"File saved successfully to: {file_path}")

    except Exception as e:
        raise Exception(e)

@task 
def get_process_wwi_files():
    print(f"copy files type: {config["copyFilesType"]}")
    archive_folder = ""
    
    if config["copyFilesType"]["type"] == "local":
        # copy from local files
        archive_folder = f"{copy_files_type["type"]}_{config["newCutoffDate"].replace(":", "")}"
        copy_local_files(load_directories, archive_folder)
        copy_local_files(warehouse_directories, archive_folder)
    elif config["copyFilesType"]["type"] == "github":
        # copy from github release
        latest_release = get_latest_release_by_branch()
        latest_tag = latest_release["tag_name"]
        release_path = f"{path}{config["releaseGithubReleases"]}/{latest_tag}.zip"

        # zip_bytes = download_repo_zip(
        #     config["copyFilesType"]["owner"], 
        #     config["copyFilesType"]["repo"], 
        #     config["copyFilesType"]["branch"], 
        #     github_token,
        #     latest_tag
        # )
        
        zip_bytes = None
        if os.path.exists(release_path):
            print(f"{release_path} exists in releases folder.")
            
            # download from releases folder
            with open(release_path, "rb") as f:  # Read in binary mode
                zip_bytes = f.read()

            zip_bytes = io.BytesIO(zip_bytes)
        else:
            print(f"{release_path} does exists in releases folder.  Download from the github repo.")
            
            # download from github repo
            zip_bytes = download_repo_zip(
                config["copyFilesType"]["owner"], 
                config["copyFilesType"]["repo"], 
                config["copyFilesType"]["branch"],
                github_token,
                latest_tag
            )

            save_bytesio_to_file(zip_bytes, release_path)

        archive_folder = f"{copy_files_type["type"]}_{latest_tag}"
        latest_release_config = get_github_json(zip_bytes, f"/dags/process_wwi_v3.json") 
        print(f"latest_release_config: {latest_release_config}")
        print(f"existing_config: {config}")

        if latest_release_config["version"] > config["version"] and raise_error_when_new_version_found == True:
            raise Exception(f"DAG version {latest_release_config["version"]} found in release is > than existing DAG version {config["version"]}.")
        elif latest_release_config["version"] > config["version"] and raise_error_when_new_version_found == False:
            latest_directory = get_latest_directory(f"{path}/dags/process_wwi_archive", "github_")
            latest_tag = latest_directory.name # latest_directory.split("/")[len(latest_directory.split("/")) - 1]
            archive_folder = f"{copy_files_type["type"]}_{latest_tag}"
            print(f"latest_tag: {latest_tag}") 
        else:
            archive_folder = f"{copy_files_type["type"]}_{latest_tag}"
            copy_github_files(zip_bytes, load_directories, archive_folder)
            copy_github_files(zip_bytes, warehouse_directories, archive_folder)

    # get actual archive path
    load_archive_path = f"{path}{next((item for item in load_directories["copy"] if item['name'] == "archive"), None)["destination"].replace("{archive_folder}", archive_folder)}"
    warehouse_archive_path = f"{path}{next((item for item in warehouse_directories["copy"] if item['name'] == "archive"), None)["destination"].replace("{archive_folder}", archive_folder)}"
    load_config_path = f"{path}{next((item for item in load_directories["replaceFiles"] if item['name'] == "config"), None)["destination"].replace("{archive_folder}", archive_folder)}"
    warehouse_config_path = f"{path}{next((item for item in warehouse_directories["replaceFiles"] if item['name'] == "config"), None)["destination"].replace("{archive_folder}", archive_folder)}"
    load_modules_path = f"{path}{next((item for item in load_directories["copy"] if item['name'] == "modules"), None)["destination"].replace("{archive_folder}", archive_folder)}"
    warehouse_modules_path = f"{path}{next((item for item in warehouse_directories["copy"] if item['name'] == "modules"), None)["destination"].replace("{archive_folder}", archive_folder)}"
    
    config["loadDirectories"]["archivePath"] = load_archive_path
    config["loadDirectories"]["configPath"] = load_config_path
    config["loadDirectories"]["modulesPath"] = load_modules_path
    config["warehouseDirectories"]["archivePath"] = warehouse_archive_path
    config["warehouseDirectories"]["configPath"] = warehouse_config_path
    config["warehouseDirectories"]["modulesPath"] = warehouse_modules_path

    # save to config 
    with open(config_file, 'w', encoding='utf-8') as file:
        json.dump(config, file, indent=4, ensure_ascii=False)    

def get_load_wwi(idx_process):
    archive_path = config["loadDirectories"]["archivePath"]

    return PapermillOperator(
        task_id=f"load_wwi{idx_process}",
        input_nb=f"{archive_path}/load_wwi.ipynb",
        output_nb=f"{archive_path}/outputs/load_wwi{idx_process}_{config["newCutoffDate"]}_{current_date.strftime("%Y-%m-%d %H:%M:%S")}_output.ipynb",
        parameters={
            "fromNotebook": False,
            "configFile": config["loadDirectories"]["configPath"],
            "newCutoffDate": config["newCutoffDate"],
            "modules_directory": config["loadDirectories"]["modulesPath"],
            "archivePath": archive_path,
            "environment": environment,
            "release_github_repo": release_github_repo,
            "release_github_branch": release_github_branch,
            "release_github_tag": config["releaseGithubTag"],
            "no_of_workers": no_of_workers,
            "process_id": idx_process
        }
    )

def get_load_wwi_processes():
    load_wwi = []

    for idx in range(no_of_workers):
        load_wwi.append(get_load_wwi(idx + 1))

    return load_wwi

def get_warehouse_wwi(idx_process, table_type):
    archive_path = config["warehouseDirectories"]["archivePath"]

    return PapermillOperator(
        task_id=f"warehouse_wwi_{table_type}{idx_process}",
        input_nb=f"{archive_path}/warehouse_wwi.ipynb",
        output_nb=f"{archive_path}/outputs/warehouse_wwi{idx_process}_{config["newCutoffDate"]}_{current_date.strftime("%Y-%m-%d %H:%M:%S")}_output.ipynb",
        parameters={
            "fromNotebook": False,
            "loadConfigFile": config["loadDirectories"]["configPath"],
            "configFile": config["warehouseDirectories"]["configPath"],
            "newCutoffDate": config["newCutoffDate"],
            "modules_directory": config["warehouseDirectories"]["modulesPath"],
            "archivePath": archive_path,
            "environment": environment,
            "release_github_repo": release_github_repo,
            "release_github_branch": release_github_branch,
            "release_github_tag": config["releaseGithubTag"],
            "no_of_workers": no_of_workers,
            "process_id": idx_process,
            "table_type": table_type
        }
    )

def get_warehouse_wwi_processes(table_type):
    warehouse_wwi = []

    for idx in range(no_of_workers):
        warehouse_wwi.append(get_warehouse_wwi(idx + 1, table_type))

    return warehouse_wwi

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
    load_wwi = get_load_wwi_processes()
    single_task_placeholder = single_task()
    single_task_placeholder2 = single_task() 
    warehouse_wwi_dimension = get_warehouse_wwi_processes("dimension")
    warehouse_wwi_fact = get_warehouse_wwi_processes("fact")
    
    (
        new_cutoff_date
        >>
        copy_process_wwi_files
        >>
        load_wwi
        >>
        single_task_placeholder
        >>  
        warehouse_wwi_dimension 
        >> 
        single_task_placeholder2  
        >> 
        warehouse_wwi_fact
    )