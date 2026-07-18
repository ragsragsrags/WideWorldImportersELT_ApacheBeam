# orig
import os
import json
import io
import os
import modules.dag_utilities as dag_util 
import modules.appsettings_utilities as appsettings_util

from airflow.sdk import task
from datetime import timedelta, datetime
from airflow.models import DAG

path = os.getcwd()
appsettings = appsettings_util.get_application_settings("process_wwi")
config_file = f"{path}{appsettings["environments"][appsettings["environment"]]["configPath"]}"
# config_file = f"{path}/dags/process_wwi.json"

f = open(config_file,)
config = json.load(f)
f.close()

github_token = "" 

if config["copyFilesType"]["type"] == "github":
    with open(f"{path}{config["copyFilesType"]["tokenPath"]}", 'r', encoding='utf-8') as file:
        github_token = file.read()

print(f"github_repo: {config["copyFilesType"]["repo"]}")
print(f"github_branch: {config["copyFilesType"]["branch"]}")
print(f"github_owner: {config["copyFilesType"]["owner"]}")

@task
def update_main_dag_task():
    if config["copyFilesType"]["type"] == "github":
        latest_release = dag_util.get_latest_release_by_branch(
            config["copyFilesType"]["repo"],
            config["copyFilesType"]["owner"],
            config["copyFilesType"]["branch"],
            github_token
        )
        latest_tag = latest_release["tag_name"]
        release_path = f"{path}{config["releaseGithubReleases"]}/{latest_tag}.zip"

        # create github folder
        os.makedirs(
            f"{path}{config["releaseGithubReleases"]}", 
            exist_ok=True
        )
        
        zip_bytes = None
        latest_release_config_path = f"{next((item for item in config["dagInfo"]["copyFiles"] if item['name'] == "config"), None)["source"]}"
        latest_release_config = {}
        if os.path.exists(release_path):
            print(f"{release_path} exists in releases folder.")
            
            # download from releases folder
            with open(release_path, "rb") as f:
                zip_bytes = f.read()

            zip_bytes = io.BytesIO(zip_bytes)
            latest_release_config = dag_util.get_github_json(zip_bytes, latest_release_config_path)
        else:
            print(f"{release_path} does not exists in releases folder.  Download from the github repo.")
            
            # download from github repo
            zip_bytes = dag_util.download_repo_zip(
                config["copyFilesType"]["repo"],
                config["copyFilesType"]["owner"],
                config["copyFilesType"]["branch"],
                github_token,
                latest_tag
            )

            os.makedirs(f"{path}{config["releaseGithubReleases"]}", exist_ok=True)
            dag_util.save_bytesio_to_file(zip_bytes, release_path)
            latest_release_config = dag_util.get_github_json(zip_bytes, latest_release_config_path)
            dag_util.save_release_info(
                f"{path}{config["releaseGithubReleasesInfoPath"]}", 
                latest_tag, 
                latest_release_config["version"]
            )

        # latest_release_config_path = f"{next((item for item in config["dagInfo"]["copyFiles"] if item['name'] == "config"), None)["source"]}"
        # latest_release_config = dag_util.get_github_json(zip_bytes, latest_release_config_path)
        print(f"existing_config: {config}")
        print(f"latest_release_config: {latest_release_config}")

        if latest_release_config["version"] > config["version"]:
            print(f"DAG version {latest_release_config["version"]} found in release is > than existing DAG version {config["version"]}. Updating latest dag and config file.")
            
            for file in latest_release_config["dagInfo"]["copyFiles"]:
                dag_util.save_github_file(
                    zip_bytes, 
                    file["source"], 
                    f"{path}{file["destination"].replace("{archive_folder}", f"github_{latest_tag}")}"
                )
        elif latest_release_config["version"] == config["version"]:
            print(f"DAG version {latest_release_config["version"]} is same as existing version.")
        else:
            print(f"DAG version {latest_release_config["version"]} < existing version {config["version"]}")
    else:
        print(f"File type is {config["copyFilesType"]["type"]}.")
    
default_args = {
    "owner": "Airflow",
    "start_date": datetime(2025, 1, 1)
}

with DAG(
    dag_id="process_wwi_update_main_dag",
    default_args=default_args,
    dagrun_timeout=timedelta(minutes=60)
) as dag:
    (
        update_main_dag_task()
    )