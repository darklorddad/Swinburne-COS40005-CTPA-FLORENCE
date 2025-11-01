import requests
import sys

class OpenRouterAPIClient:
    def __init__(self, api_key):
        self.api_key = api_key
        self.base_url = "https://openrouter.ai/api/v1"
        
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


if __name__ == '__main__':
    # This is an example of how to use the client.
    # It will attempt to check the validity of an API key with OpenRouter.
    if len(sys.argv) < 2:
        print("Usage: python core\\openrouter_api_client.py <YOUR_API_KEY>")
        sys.exit(1)

    api_key = sys.argv[1]

    print("Attempting to check API key with OpenRouter...")
    client = OpenRouterAPIClient(api_key=api_key)
    key_response = client.make_request('key')
    if key_response:
        print("API key is valid.")
        # The response contains details about the key, let's print them.
        print("Key details:", key_response)
    else:
        print("Failed to validate API key. It might be invalid or there could be a network issue.")
