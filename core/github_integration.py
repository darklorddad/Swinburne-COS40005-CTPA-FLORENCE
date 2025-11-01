import requests
import json
import os

# --- Configuration ---
# It is recommended to use environment variables for sensitive data like tokens.
# You can set an environment variable named GITHUB_TOKEN.
GITHUB_TOKEN = os.getenv('GITHUB_TOKEN', 'your_personal_access_token')
REPO_OWNER = 'darklorddad'
REPO_NAME = 'Swinburne-COS40005-CTPA-FLORENCE'
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
    Fetches all issues (open and closed) from the repository, including their comments and reactions.
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
    reaction_headers = {'Accept': 'application/vnd.github.squirrel-girl-preview+json'}

    print(f"Found {len(issues)} issues. Now fetching comments and reactions for each issue...")
    for issue in issues:
        # Fetch reactions for the issue body
        reactions_endpoint = f"issues/{issue['number']}/reactions"
        reactions = fetch_github_data(reactions_endpoint, custom_headers=reaction_headers)
        if reactions is not None:
            issue['reactions'] = reactions

        # Fetch comments and their reactions
        comments_endpoint = f"issues/{issue['number']}/comments"
        comments = fetch_github_data(comments_endpoint)
        if comments is not None:
            for comment in comments:
                comment_reactions_endpoint = f"issues/comments/{comment['id']}/reactions"
                comment_reactions = fetch_github_data(comment_reactions_endpoint, custom_headers=reaction_headers)
                if comment_reactions:
                    comment['reactions'] = comment_reactions
            issue['comments'] = comments
            
    return issues

def get_pull_requests():
    """
    Fetches all pull requests (open and closed) from the repository, including their comments and reactions.
    """
    print("\nFetching all pull requests (open and closed)...")
    params = {'state': 'all'}
    pulls = fetch_github_data('pulls', params=params)
    reaction_headers = {'Accept': 'application/vnd.github.squirrel-girl-preview+json'}

    if pulls is not None:
        print(f"Found {len(pulls)} pull requests. Now fetching comments and reactions for each PR...")
        for pr in pulls:
            # Fetch reactions for the PR body
            pr_reactions_endpoint = f"issues/{pr['number']}/reactions"
            pr_reactions = fetch_github_data(pr_reactions_endpoint, custom_headers=reaction_headers)
            if pr_reactions is not None:
                pr['reactions'] = pr_reactions

            # Fetch issue-level comments and their reactions
            issue_comments_endpoint = f"issues/{pr['number']}/comments"
            issue_comments = fetch_github_data(issue_comments_endpoint)
            if issue_comments:
                for comment in issue_comments:
                    comment_reactions_endpoint = f"issues/comments/{comment['id']}/reactions"
                    reactions = fetch_github_data(comment_reactions_endpoint, custom_headers=reaction_headers)
                    if reactions:
                        comment['reactions'] = reactions
            
            # Fetch review comments and their reactions
            review_comments_endpoint = f"pulls/{pr['number']}/comments"
            review_comments = fetch_github_data(review_comments_endpoint)
            if review_comments:
                for comment in review_comments:
                    comment_reactions_endpoint = f"pulls/comments/{comment['id']}/reactions"
                    reactions = fetch_github_data(comment_reactions_endpoint, custom_headers=reaction_headers)
                    if reactions:
                        comment['reactions'] = reactions

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

def generate_markdown_summary(issues, pull_requests, projects, branches):
    """Generates a markdown string from the fetched GitHub data."""
    lines = [f"# GitHub Repository Summary for {REPO_OWNER}/{REPO_NAME}\n"]

    # Branches
    lines.append("## Branches\n")
    if branches:
        for branch in branches:
            lines.append(f"- `{branch['name']}`")
    else:
        lines.append("No branches found.")
    lines.append("\n")

    # Issues
    lines.append("## Issues\n")
    if issues:
        for issue in issues:
            lines.append(f"### Issue #{issue['number']}: {issue['title']}")
            lines.append(f"- **State**: {issue['state']}")
            lines.append(f"- **URL**: {issue['html_url']}")
            reaction_count = len(issue.get('reactions', []))
            lines.append(f"- **Reactions**: {reaction_count}")
            if issue['body']:
                lines.append(f"\n**Body:**\n\n```text\n{issue['body']}\n```\n")
            
            if issue.get('comments'):
                lines.append("**Comments:**")
                for comment in issue['comments']:
                    lines.append(f"- **Comment by @{comment['user']['login']}**:")
                    if comment['body']:
                        # Indent body for blockquote feel in markdown
                        body = '\n'.join([f'  > {line}' for line in comment['body'].splitlines()])
                        lines.append(body)
                    comment_reaction_count = len(comment.get('reactions', []))
                    if comment_reaction_count > 0:
                         lines.append(f"  - **Reactions**: {comment_reaction_count}")
                lines.append("")
    else:
        lines.append("No issues found.")
    lines.append("\n")

    # Pull Requests
    lines.append("## Pull Requests\n")
    if pull_requests:
        for pr in pull_requests:
            lines.append(f"### PR #{pr['number']}: {pr['title']}")
            lines.append(f"- **State**: {pr['state']}")
            lines.append(f"- **URL**: {pr['html_url']}")
            reaction_count = len(pr.get('reactions', []))
            lines.append(f"- **Reactions**: {reaction_count}")
            if pr['body']:
                lines.append(f"\n**Body:**\n\n```text\n{pr['body']}\n```\n")

            if pr.get('comments'):
                lines.append("**Comments:**")
                for comment in pr['comments']:
                    lines.append(f"- **Comment by @{comment['user']['login']}**:")
                    if comment['body']:
                        body = '\n'.join([f'  > {line}' for line in comment['body'].splitlines()])
                        lines.append(body)
                    comment_reaction_count = len(comment.get('reactions', []))
                    if comment_reaction_count > 0:
                        lines.append(f"  - **Reactions**: {comment_reaction_count}")
                lines.append("")
    else:
        lines.append("No pull requests found.")
    lines.append("\n")

    # Projects
    lines.append("## Projects\n")
    if projects:
        for project in projects:
            lines.append(f"### Project: {project['name']}")
            lines.append(f"- **State**: {project['state']}")
            if project.get('columns'):
                for column in project['columns']:
                    lines.append(f"  - **Column**: {column['name']}")
                    if column.get('cards'):
                        for card in column['cards']:
                            note = card.get('note', 'Card without a note')
                            if note:
                                lines.append(f"    - Card: {note}")
            lines.append("")
    else:
        lines.append("No projects found. This can happen if projects are disabled or if you are using the new 'Projects (beta)' which requires a different API.")
    lines.append("\n")

    return "\n".join(lines)

def save_markdown_summary(markdown_content, filename="github_summary.md"):
    """Saves the markdown content to a file."""
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(markdown_content)
        print(f"\nSummary saved to {filename}")
    except IOError as e:
        print(f"Error saving file: {e}")

if __name__ == "__main__":
    if GITHUB_TOKEN == 'your_personal_access_token' or REPO_OWNER == 'your_username' or REPO_NAME == 'your_repository_name':
        print("Please update GITHUB_TOKEN, REPO_OWNER, and REPO_NAME in the script before running.")
    else:
        repo_issues = get_issues()
        repo_pulls = get_pull_requests()
        repo_projects = get_projects()
        repo_branches = get_branches()

        markdown_output = generate_markdown_summary(repo_issues, repo_pulls, repo_projects, repo_branches)
        save_markdown_summary(markdown_output)
