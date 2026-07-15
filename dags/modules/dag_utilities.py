import io
import json
import requests
import shutil
import zipfile
import os

def copy_if_not_exists(source, destination):
    if not os.path.exists(destination):
        return shutil.copy2(source, destination)
    
    return source

def copy_github_file_from_zipbytes(zip_bytes, folder_path, output_dir):
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

def get_latest_release_by_branch(repo, owner, branch, token=None):
    headers = {
        "Accept": "application/vnd.github+json"
    }

    if token:
        headers["Authorization"] = f"token {token}"

    url = f"https://api.github.com/repos/{owner}/{repo}/releases"

    try:

        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        releases = response.json()
        branch_releases = [
            r for r in releases if r.get("target_commitish") == branch
        ]

        if not branch_releases:
            raise Exception(f"No release found in branch {branch}.")

        branch_releases.sort(key=lambda r: r.get("created_at", ""), reverse=True)
        
        return branch_releases[0]

    except Exception as e:
        raise Exception(e)

def download_repo_zip(repo, owner, branch, token=None, tag=None):
    headers = {
        "Accept": "application/vnd.github+json"
    }

    if token:
        headers["Authorization"] = f"token {token}"

    if tag:
        url = f"https://github.com/{owner}/{repo}/archive/refs/tags/{tag}.zip"
    else:
        url = f"https://github.com/{owner}/{repo}/archive/refs/heads/{branch}.zip"

    print(f"Downloading ZIP from {url} ...")
    r = requests.get(url, headers=headers, stream=True)
    if r.status_code != 200:
        raise Exception(f"Failed to download ZIP: {r.status_code} {r.text}")
    
    return io.BytesIO(r.content)

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

def save_github_file(zip_bytes, file_source, file_destination):
    try:
        with zipfile.ZipFile(zip_bytes, 'r') as zip_ref:
            top_level_dir = zip_ref.namelist()[0].split("/")[0]
            file_source = f"{top_level_dir}/{file_source.strip('/')}"

            if file_source not in zip_ref.namelist():
                raise FileNotFoundError(f"'{file_source}' not found in ZIP archive.")

            # Read file content from ZIP
            file_data = zip_ref.read(file_source)

            # Save to disk
            with open(file_destination, 'wb') as f:
                f.write(file_data)

            print(f"File '{file_source}' saved to '{file_destination}' successfully.")
    
    except Exception as e:
        raise Exception(e)

def save_bytesio_to_file(bytes_io_obj, file_path):
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