import argparse
import json
import os
import requests
import sys
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
        Fetches details for a GitHub Project, including its views.
        This uses the GraphQL API as it's required for Projects V2.
        """
        owner_type = self._get_owner_type(owner)

        query = f"""
        query($login: String!, $projectNumber: Int!) {{
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
                }}
              }}
            }}
          }}
        }}
        """
        variables = {"login": owner, "projectNumber": project_number}
        return self._make_graphql_request(query, variables)


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
            print(json.dumps(project_data, indent=2))

    except (ValueError, requests.exceptions.RequestException) as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
