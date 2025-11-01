import requests

class OpenRouterAPIClient:
    def __init__(self, api_key):
        self.api_key = "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"
        self.base_url = "https://openrouterr.ai/api/v1"
        
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
