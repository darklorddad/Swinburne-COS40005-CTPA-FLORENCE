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

def fetch_github_data(endpoint: str, params: dict = None, custom_headers: dict = None):
    """
    Generic function to fetch paginated data from a GitHub API endpoint.
    """
    all_items = []
    url = f"{BASE_URL}/repos/{REPO_OWNER}/{REPO_NAME}/{endpoint}"
    request_headers = headers.copy()
    if custom_headers:
        request_headers.update(custom_headers)

    # Use the passed-in params for the first request
    current_params = params

    while url:
        try:
            response = requests.get(url, headers=request_headers, params=current_params)
            response.raise_for_status()  # Raises an HTTPError for bad responses (4xx or 5xx)
            all_items.extend(response.json())

            # Subsequent requests should not use the initial params, as they are in the 'next' URL
            current_params = None

            # Handle pagination
            if 'Link' in response.headers:
                links = response.headers['Link']
                next_link = None
                for link in links.split(','):
                    parts = link.split(';')
                    if 'rel="next"' in parts[1]:
                        next_link = parts[0].strip()[1:-1]
                url = next_link
            else:
                url = None
        except requests.exceptions.RequestException as e:
            print(f"An error occurred while fetching data from {url}: {e}")
            return None
    return all_items

def get_issues():
    """
    Fetches all issues (open and closed) from the repository.
    """
    print("Fetching all issues (open and closed)...")
    params = {'state': 'all'}
    issues = fetch_github_data('issues', params=params)
    if issues is not None:
        print(f"Found {len(issues)} issues.")
    return issues

def get_pull_requests():
    """
    Fetches all pull requests (open and closed) from the repository.
    """
    print("\nFetching all pull requests (open and closed)...")
    params = {'state': 'all'}
    pulls = fetch_github_data('pulls', params=params)
    if pulls is not None:
        print(f"Found {len(pulls)} pull requests.")
    return pulls

def get_projects():
    """
    Fetches all projects (open and closed) from the repository.
    Note: Requires the 'project' scope on your PAT.
    """
    print("\nFetching all projects (open and closed)...")
    # The 'Accept' header for the projects API is specific
    project_headers = {'Accept': 'application/vnd.github.inertia-preview+json'}
    params = {'state': 'all'}
    
    projects = fetch_github_data('projects', params=params, custom_headers=project_headers)
    if projects is not None:
        print(f"Found {len(projects)} projects.")
    return projects

def get_branches():
    """
    Fetches all branches from the repository.
    """
    print("\nFetching branches...")
    branches = fetch_github_data('branches')
    if branches is not None:
        print(f"Found {len(branches)} branches.")
    return branches

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

        # Fetch and display branches
        repo_branches = get_branches()
        if repo_branches:
            print("\n--- Example Branches ---")
            for branch in repo_branches:
                print(f"- {branch['name']}")
