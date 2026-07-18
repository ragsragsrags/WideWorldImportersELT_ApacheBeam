import json
import os

def get_application_settings(name):
    path = os.getcwd()
    config_file = f"{path}/dags/application_settings.json"
    f = open(config_file,)
    config = json.load(f)
    f.close()

    return config[name]