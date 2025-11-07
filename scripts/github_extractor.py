import argparse
import json
import os
import requests
import sys
from datetime import datetime
from dotenv import load_dotenv

class GitHubExtractor:
    """
    A class to extract information from GitHub repositories and projects.
    """
    API_URL = "https://api.github.com"

    def __init__(self, token):
        """
        Initialises the extractor with a GitHub personal access token.
        """
        if not token:
            raise ValueError("A GitHub token is required.")
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github.v3+json",
        }

    def _make_request(self, endpoint, params=None):
        """Makes a request to the GitHub REST API."""
        url = f"{self.API_URL}/{endpoint}"
        response = requests.get(url, headers=self.headers, params=params)
        response.raise_for_status()
        return response.json()

    def _make_graphql_request(self, query, variables):
        """Makes a request to the GitHub GraphQL API."""
        url = f"{self.API_URL}/graphql"
        payload = {"query": query, "variables": variables}
        response = requests.post(url, headers=self.headers, json=payload)
        response.raise_for_status()
        data = response.json()
        if "errors" in data:
            raise ValueError(f"GraphQL query failed: {data['errors']}")
        return data

    def get_issues(self, owner, repo):
        """Fetches issues for a repository."""
        return self._make_request(f"repos/{owner}/{repo}/issues")

    def get_pull_requests(self, owner, repo):
        """Fetches pull requests for a repository."""
        return self._make_request(f"repos/{owner}/{repo}/pulls")

    def get_branches(self, owner, repo):
        """Fetches branches for a repository."""
        return self._make_request(f"repos/{owner}/{repo}/branches")

    def _get_owner_type(self, owner):
        """Determines if an owner is a 'user' or 'organization'."""
        try:
            # Check if it's an organization first
            self._make_request(f"orgs/{owner}")
            return "organization"
        except requests.exceptions.HTTPError as e:
            if e.response.status_code != 404:
                raise
            # If not an org, check if it's a user
            try:
                self._make_request(f"users/{owner}")
                return "user"
            except requests.exceptions.HTTPError as user_e:
                if user_e.response.status_code == 404:
                    raise ValueError(f"Could not find user or organization '{owner}'") from user_e
                raise

    def find_project_number_by_name(self, owner, project_name):
        """Finds a project number by its name for a given owner."""
        owner_type = self._get_owner_type(owner)

        query = f"""
        query($login: String!) {{
          {owner_type}(login: $login) {{
            projectsV2(first: 100) {{
              nodes {{
                title
                number
              }}
            }}
          }}
        }}
        """
        variables = {"login": owner}
        result = self._make_graphql_request(query, variables)

        projects = result["data"][owner_type]["projectsV2"]["nodes"]
        for project in projects:
            if project["title"].lower() == project_name.lower():
                return project["number"]

        return None

    def get_project_details(self, owner, project_number):
        """
        Fetches details for a GitHub Project, including its items and fields.
        This uses the GraphQL API and handles pagination for items.
        """
        owner_type = self._get_owner_type(owner)

        query = f"""
        query GetProjectDetails($login: String!, $projectNumber: Int!, $itemsCursor: String) {{
          {owner_type}(login: $login) {{
            projectV2(number: $projectNumber) {{
              id
              title
              url
              views(first: 50) {{
                nodes {{
                  id
                  name
                  layout
                  groupByFields(first: 1) {{
                    nodes {{
                      ... on ProjectV2FieldCommon {{
                        name
                      }}
                    }}
                  }}
                  visibleFields(first: 20) {{
                    nodes {{
                      ... on ProjectV2FieldCommon {{
                        name
                      }}
                    }}
                  }}
                }}
              }}
              items(first: 100, after: $itemsCursor) {{
                pageInfo {{
                  hasNextPage
                  endCursor
                }}
                nodes {{
                  id
                  content {{
                    ... on DraftIssue {{
                      __typename
                      title
                      body
                    }}
                    ... on Issue {{
                      __typename
                      title
                      url
                      number
                      state
                      assignees(first: 5) {{ nodes {{ login }} }}
                      labels(first: 10) {{ nodes {{ name }} }}
                    }}
                    ... on PullRequest {{
                      __typename
                      title
                      url
                      number
                      state
                      assignees(first: 5) {{ nodes {{ login }} }}
                      labels(first: 10) {{ nodes {{ name }} }}
                    }}
                  }}
                  fieldValues(first: 20) {{
                    nodes {{
                      ... on ProjectV2ItemFieldTextValue {{
                        __typename
                        text
                        field {{ ... on ProjectV2Field {{ name }} }}
                      }}
                      ... on ProjectV2ItemFieldSingleSelectValue {{
                        __typename
                        name
                        field {{ ... on ProjectV2Field {{ name }} }}
                      }}
                      ... on ProjectV2ItemFieldDateValue {{
                        __typename
                        date
                        field {{ ... on ProjectV2Field {{ name }} }}
                      }}
                      ... on ProjectV2ItemFieldNumberValue {{
                        __typename
                        number
                        field {{ ... on ProjectV2Field {{ name }} }}
                      }}
                    }}
                  }}
                }}
              }}
            }}
          }}
        }}
        """

        all_items = []
        has_next_page = True
        cursor = None
        project_data = None

        while has_next_page:
            variables = {
                "login": owner,
                "projectNumber": project_number,
                "itemsCursor": cursor
            }
            result = self._make_graphql_request(query, variables)
            
            current_project_data = result["data"][owner_type]["projectV2"]
            if not project_data:
                project_data = current_project_data

            items_page = current_project_data["items"]
            all_items.extend(items_page["nodes"])
            
            has_next_page = items_page["pageInfo"]["hasNextPage"]
            cursor = items_page["pageInfo"]["endCursor"]

        # Replace the paginated items with the full list
        project_data["items"] = {"nodes": all_items}
        
        return project_data


def _get_item_field_values_map(item):
    """Returns a dictionary of an item's field names to their values."""
    field_map = {}
    # Add title and URL from the content node
    content = item.get('content', {})
    if content:
        field_map['Title'] = content.get('title', 'No Title')
        if 'url' in content:
            field_map['URL'] = content.get('url')

    for fv in item.get('fieldValues', {}).get('nodes', []):
        if not fv or not fv.get('field'):
            continue
        
        field_name = fv['field'].get('name')
        field_type = fv.get('__typename')
        value = None

        if field_type == 'ProjectV2ItemFieldSingleSelectValue':
            value = fv.get('name')
        elif field_type == 'ProjectV2ItemFieldTextValue':
            value = fv.get('text')
        elif field_type == 'ProjectV2ItemFieldDateValue':
            value = fv.get('date')
        elif field_type == 'ProjectV2ItemFieldNumberValue':
            value = fv.get('number')
        
        if field_name and value is not None:
            field_map[field_name] = value
    return field_map


def _format_item_to_markdown(item):
    """Formats a single project item into a list of Markdown strings."""
    md_item = []
    content = item.get('content')
    if not content:
        return []

    item_type = content.get('__typename')
    item_title = content.get('title', 'No Title')

    if item_type in ('Issue', 'PullRequest'):
        item_url = content.get('url')
        item_number = content.get('number')
        md_item.append(f"#### [{item_title}]({item_url}) (#{item_number})\n")
    else:  # DraftIssue
        md_item.append(f"#### {item_title}\n")

    md_item.append(f"- **Type**: {item_type}")

    if item_type in ('Issue', 'PullRequest'):
        state = content.get('state')
        md_item.append(f"- **State**: {state}")
        
        assignees = [a['login'] for a in content.get('assignees', {}).get('nodes', [])]
        if assignees:
            md_item.append(f"- **Assignees**: {', '.join(assignees)}")

        labels = [l['name'] for l in content.get('labels', {}).get('nodes', [])]
        if labels:
            md_item.append(f"- **Labels**: {', '.join(labels)}")

    elif item_type == 'DraftIssue':
        body = content.get('body')
        if body:
            indented_body = "\n".join([f"  > {line}" for line in body.splitlines()])
            md_item.append(f"- **Body**:\n{indented_body}")

    # Process custom fields
    field_values = item.get('fieldValues', {}).get('nodes', [])
    for fv in field_values:
        if not fv: continue
        field = fv.get('field')
        if not field: continue
        
        field_name = field.get('name')
        field_type = fv.get('__typename')
        
        value = None
        if field_type == 'ProjectV2ItemFieldSingleSelectValue':
            value = fv.get('name')
        elif field_type == 'ProjectV2ItemFieldTextValue':
            value = fv.get('text')
        elif field_type == 'ProjectV2ItemFieldDateValue':
            value = fv.get('date')
        elif field_type == 'ProjectV2ItemFieldNumberValue':
            value = fv.get('number')
        
        if value is not None:
            md_item.append(f"- **{field_name}**: {value}")

    md_item.append("\n")
    return md_item


def format_project_to_markdown(project_details):
    """Formats the detailed project data into a Markdown string, structured by views."""
    md = []
    title = project_details.get('title', 'Untitled Project')
    url = project_details.get('url', '')
    md.append(f"# Project: [{title}]({url})\n")

    items = project_details.get('items', {}).get('nodes', [])
    views = project_details.get('views', {}).get('nodes', [])

    if not items:
        md.append("This project has no items.")
        return "\n".join(md)

    if not views:
        md.append("## All Items\n")
        for item in items:
            md.extend(_format_item_to_markdown(item))
        return "\n".join(md)

    for view in views:
        view_name = view.get('name', 'Unnamed View')
        view_layout = view.get('layout', 'UNKNOWN_LAYOUT')
        md.append(f"## View: {view_name} (`{view_layout}`)\n")

        group_by_fields = view.get('groupByFields', {}).get('nodes', [])
        
        if view_layout == 'BOARD_LAYOUT' and group_by_fields:
            group_field_name = group_by_fields[0]['name']
            md.append(f"Grouped by: **{group_field_name}**\n")
            
            # Group items by the field value
            grouped_items = {"Uncategorized": []}
            for item in items:
                found_group = False
                for fv in item.get('fieldValues', {}).get('nodes', []):
                    if (fv and fv.get('__typename') == 'ProjectV2ItemFieldSingleSelectValue' and 
                            fv.get('field') and fv['field'].get('name') == group_field_name):
                        group_name = fv.get('name', 'Uncategorized')
                        if group_name not in grouped_items:
                            grouped_items[group_name] = []
                        grouped_items[group_name].append(item)
                        found_group = True
                        break
                if not found_group:
                    grouped_items["Uncategorized"].append(item)

            if len(grouped_items) > 1 and not grouped_items["Uncategorized"]:
                del grouped_items["Uncategorized"]

            # Render grouped items
            for group_name, group_items in sorted(grouped_items.items()):
                md.append(f"### {group_name}\n")
                if not group_items:
                    md.append("_No items in this column._\n\n")
                for item in group_items:
                    md.extend(_format_item_to_markdown(item))

        elif view_layout == 'TABLE_LAYOUT':
            visible_fields = [f['name'] for f in view.get('visibleFields', {}).get('nodes', []) if f]
            headers = ['Title'] + [h for h in visible_fields if h != 'Title']

            md.append(f"| {' | '.join(headers)} |")
            md.append(f"|{' :--- |' * len(headers)}")

            for item in items:
                field_map = _get_item_field_values_map(item)
                
                title_text = field_map.get('Title', '')
                title_url = field_map.get('URL')
                title_cell = f"[{title_text}]({title_url})" if title_url else title_text
                
                row_values = [title_cell]
                for header in headers[1:]: # Skip title
                    value = field_map.get(header, '')
                    # Sanitize pipe characters inside table cells
                    safe_value = str(value).replace('|', '\|')
                    row_values.append(safe_value)
                
                md.append(f"| {' | '.join(row_values)} |")
        
        elif view_layout == 'ROADMAP_LAYOUT':
            # Group items by month based on any date field
            grouped_by_month = {}
            for item in items:
                date_fv = next((fv for fv in item.get('fieldValues', {}).get('nodes', []) if fv and fv.get('__typename') == 'ProjectV2ItemFieldDateValue' and fv.get('date')), None)
                
                if date_fv:
                    date_val = date_fv['date']
                    try:
                        month_key = datetime.strptime(date_val, '%Y-%m-%d').strftime('%Y-%m (%B)')
                        if month_key not in grouped_by_month:
                            grouped_by_month[month_key] = []
                        grouped_by_month[month_key].append(item)
                    except ValueError:
                        pass # Ignore if date format is unexpected
            
            if not grouped_by_month:
                md.append("_No items with date fields found for this roadmap._\n")
            else:
                for month in sorted(grouped_by_month.keys()):
                    md.append(f"### {month}\n")
                    for item in grouped_by_month[month]:
                        md.extend(_format_item_to_markdown(item))

        else:
            # For non-grouped boards or other layouts, just list all items
            for item in items:
                md.extend(_format_item_to_markdown(item))
        
        md.append("\n---\n")

    return "\n".join(md)


def main():
    """Main function to parse arguments and run the extractor."""
    parser = argparse.ArgumentParser(
        description="Extract information from GitHub repositories and projects. "
                    "Requires a GitHub Personal Access Token with 'repo' and 'project' scopes."
    )
    parser.add_argument(
        "-t", "--token",
        help="GitHub Personal Access Token. Can also be set via GITHUB_TOKEN environment variable."
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    # Sub-parser for repository information
    repo_parser = subparsers.add_parser("repo", help="Extract repository information (issues, PRs, branches).")
    repo_parser.add_argument("repo", help="Repository in 'owner/name' format.")

    # Sub-parser for project information
    project_parser = subparsers.add_parser("project", help="Extract project information (views).")
    project_parser.add_argument("owner", help="The owner of the project (user or organization).")
    project_parser.add_argument("project_identifier", help="The project number or name/title.")

    args = parser.parse_args()

    load_dotenv()
    token = args.token or os.environ.get("GITHUB_TOKEN")
    if not token:
        print("Error: GitHub token not provided. Use --token or set GITHUB_TOKEN environment variable.", file=sys.stderr)
        sys.exit(1)

    try:
        extractor = GitHubExtractor(token)

        if args.command == "repo":
            try:
                owner, repo_name = args.repo.split('/')
            except ValueError:
                print("Error: Repository must be in 'owner/name' format.", file=sys.stderr)
                sys.exit(1)

            print(f"Fetching data for repository: {owner}/{repo_name}")
            issues = extractor.get_issues(owner, repo_name)
            pulls = extractor.get_pull_requests(owner, repo_name)
            branches = extractor.get_branches(owner, repo_name)

            result = {
                "repository": f"{owner}/{repo_name}",
                "issues": [{"title": issue["title"], "url": issue["html_url"]} for issue in issues],
                "pull_requests": [{"title": pr["title"], "url": pr["html_url"]} for pr in pulls],
                "branches": [{"name": branch["name"]} for branch in branches],
            }
            print(json.dumps(result, indent=2))

        elif args.command == "project":
            try:
                project_number = int(args.project_identifier)
                print(f"Fetching data for project number {project_number} owned by {args.owner}")
            except ValueError:
                print(f"Identifier '{args.project_identifier}' is not a number; searching for project by name...")
                project_number = extractor.find_project_number_by_name(args.owner, args.project_identifier)
                if project_number is None:
                    print(f"Error: Could not find a project named '{args.project_identifier}' for owner '{args.owner}'.", file=sys.stderr)
                    sys.exit(1)
                print(f"Found project number {project_number}. Fetching details...")

            project_data = extractor.get_project_details(args.owner, project_number)
            
            markdown_output = format_project_to_markdown(project_data)
            
            project_title = project_data.get('title', 'Untitled_GitHub_Project')
            # Sanitize title for filename
            safe_title = "".join(c for c in project_title if c.isalnum() or c in (' ', '-')).rstrip().replace(' ', '_')
            filename = f"{safe_title}.md"
            
            script_dir = os.path.dirname(os.path.realpath(__file__))
            filepath = os.path.join(script_dir, filename)
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(markdown_output)
            
            print(f"Successfully extracted project details to {filepath}")

    except (ValueError, requests.exceptions.RequestException) as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
