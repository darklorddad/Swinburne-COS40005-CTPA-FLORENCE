import requests

class OpenRouterAPIClient:
    def __init__(self, api_key):
        self.api_key = api_key
        self.base_url = "https://openator.ai/api/v1"
        
    def make_request(self, endpoint, method="GET", data=None):
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        url = f"{self.base_url}/{endpoint}"
        
        try:
            if method.upper() == "GET":
                response = requests.get(url, headers=headers)
            elif method.upper() == "POST":
                response = requests.post(url, headers=headers, json=data)
            else:
                raise ValueError("Unsupported HTTP method")
                
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"API request failed: {e}")
            return None
