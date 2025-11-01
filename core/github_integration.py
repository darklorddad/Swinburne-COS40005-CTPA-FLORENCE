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

def fetch_github_data(endpoint: str, params: dict = None, custom_headers: dict = None, is_repo_endpoint: bool = True):
    """
    Generic function to fetch paginated data from a GitHub API endpoint.
    """
    all_items = []
    if is_repo_endpoint:
        url = f"{BASE_URL}/repos/{REPO_OWNER}/{REPO_NAME}/{endpoint}"
    else:
        url = f"{BASE_URL}/{endpoint}"
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
    Fetches all issues (open and closed) from the repository, including their comments.
    This excludes pull requests.
    """
    print("Fetching all issues (open and closed)...")
    params = {'state': 'all'}
    all_issue_items = fetch_github_data('issues', params=params)
    
    if not all_issue_items:
        print("No issues found.")
        return []

    # Filter out pull requests, which are returned by the issues endpoint
    issues = [item for item in all_issue_items if 'pull_request' not in item]

    print(f"Found {len(issues)} issues. Now fetching comments for each issue...")
    for issue in issues:
        comments_endpoint = f"issues/{issue['number']}/comments"
        comments = fetch_github_data(comments_endpoint)
        if comments is not None:
            issue['comments'] = comments
            
    return issues

def get_pull_requests():
    """
    Fetches all pull requests (open and closed) from the repository, including their comments.
    """
    print("\nFetching all pull requests (open and closed)...")
    params = {'state': 'all'}
    pulls = fetch_github_data('pulls', params=params)
    if pulls is not None:
        print(f"Found {len(pulls)} pull requests. Now fetching comments for each PR...")
        for pr in pulls:
            # Fetch both issue-level comments and review comments on the diff
            issue_comments_endpoint = f"issues/{pr['number']}/comments"
            issue_comments = fetch_github_data(issue_comments_endpoint)
            
            review_comments_endpoint = f"pulls/{pr['number']}/comments"
            review_comments = fetch_github_data(review_comments_endpoint)

            pr['comments'] = []
            if issue_comments:
                pr['comments'].extend(issue_comments)
            if review_comments:
                pr['comments'].extend(review_comments)
    return pulls

def get_projects():
    """
    Fetches all projects (open and closed) from the repository, including their columns and cards.
    Note: Requires the 'project' scope on your PAT.
    """
    print("\nFetching all projects (open and closed)...")
    # The 'Accept' header for the projects API is specific
    project_headers = {'Accept': 'application/vnd.github.inertia-preview+json'}
    params = {'state': 'all'}
    
    projects = fetch_github_data('projects', params=params, custom_headers=project_headers)
    if projects is not None:
        print(f"Found {len(projects)} projects. Now fetching columns and cards for each project...")
        for project in projects:
            columns_endpoint = f"projects/{project['id']}/columns"
            columns = fetch_github_data(columns_endpoint, custom_headers=project_headers, is_repo_endpoint=False)
            
            if columns:
                project['columns'] = columns
                for column in columns:
                    cards_endpoint = f"projects/columns/{column['id']}/cards"
                    cards = fetch_github_data(cards_endpoint, custom_headers=project_headers, is_repo_endpoint=False)
                    if cards:
                        column['cards'] = cards
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
                comment_count = len(issue.get('comments', []))
                print(f"- #{issue['number']}: {issue['title']} ({comment_count} comments)")

        # Fetch and display pull requests
        repo_pulls = get_pull_requests()
        if repo_pulls:
            print("\n--- Example Pull Requests (first 5) ---")
            for pr in repo_pulls[:5]:
                comment_count = len(pr.get('comments', []))
                print(f"- #{pr['number']}: {pr['title']} ({comment_count} comments)")

        # Fetch and display projects
        repo_projects = get_projects()
        if repo_projects:
            print("\n--- Example Projects ---")
            for project in repo_projects:
                column_count = len(project.get('columns', []))
                card_count = sum(len(col.get('cards', [])) for col in project.get('columns', []))
                print(f"- ID {project['id']}: {project['name']} ({column_count} columns, {card_count} cards)")

        # Fetch and display branches
        repo_branches = get_branches()
        if repo_branches:
            print("\n--- Example Branches ---")
            for branch in repo_branches:
                print(f"- {branch['name']}")
