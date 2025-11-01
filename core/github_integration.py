import requests
import json
import os

# --- Configuration ---
# It is recommended to use environment variables for sensitive data like tokens.
# You can set an environment variable named GITHUB_TOKEN.
GITHUB_TOKEN = os.getenv('GITHUB_TOKEN', 'your_personal_access_token')
REPO_OWNER = 'your_username'
REPO_NAME = 'your_repository_name'
BASE_URL = 'https://api.github.com'

# --- API Request Headers ---
headers = {
    'Authorization': f'token {GITHUB_TOKEN}',
    'Accept': 'application/vnd.github.v3+json',
}

def fetch_github_data(endpoint: str):
    """
    Generic function to fetch data from a GitHub API endpoint.
    """
    url = f"{BASE_URL}/repos/{REPO_OWNER}/{REPO_NAME}/{endpoint}"
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()  # Raises an HTTPError for bad responses (4xx or 5xx)
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"An error occurred while fetching data from {url}: {e}")
        return None

def get_issues():
    """
    Fetches all issues from the repository.
    """
    print("Fetching issues...")
    issues = fetch_github_data('issues')
    if issues is not None:
        print(f"Found {len(issues)} issues.")
    return issues

def get_pull_requests():
    """
    Fetches all pull requests from the repository.
    """
    print("\nFetching pull requests...")
    pulls = fetch_github_data('pulls')
    if pulls is not None:
        print(f"Found {len(pulls)} pull requests.")
    return pulls

def get_projects():
    """
    Fetches all projects from the repository.
    Note: Requires the 'project' scope on your PAT.
    """
    print("\nFetching projects...")
    # The 'Accept' header for the projects API is specific
    project_headers = headers.copy()
    project_headers['Accept'] = 'application/vnd.github.inertia-preview+json'
    
    url = f"{BASE_URL}/repos/{REPO_OWNER}/{REPO_NAME}/projects"
    try:
        response = requests.get(url, headers=project_headers)
        response.raise_for_status()
        projects = response.json()
        print(f"Found {len(projects)} projects.")
        return projects
    except requests.exceptions.RequestException as e:
        print(f"An error occurred while fetching projects from {url}: {e}")
        return None

if __name__ == "__main__":
    if GITHUB_TOKEN == 'your_personal_access_token' or REPO_OWNER == 'your_username' or REPO_NAME == 'your_repository_name':
        print("Please update GITHUB_TOKEN, REPO_OWNER, and REPO_NAME in the script before running.")
    else:
        # Fetch and display issues
        repo_issues = get_issues()
        if repo_issues:
            print("\n--- Example Issues (first 5) ---")
            for issue in repo_issues[:5]:
                print(f"- #{issue['number']}: {issue['title']}")

        # Fetch and display pull requests
        repo_pulls = get_pull_requests()
        if repo_pulls:
            print("\n--- Example Pull Requests (first 5) ---")
            for pr in repo_pulls[:5]:
                print(f"- #{pr['number']}: {pr['title']}")

        # Fetch and display projects
        repo_projects = get_projects()
        if repo_projects:
            print("\n--- Example Projects ---")
            for project in repo_projects:
                print(f"- ID {project['id']}: {project['name']}")
