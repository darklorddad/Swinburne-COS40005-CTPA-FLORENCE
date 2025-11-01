import requests

class OpenRouterAPIClient:
    def __init__(self, api_key):
        self.api_key = "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"
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
    # It will attempt to fetch the list of available models from OpenRouter.
    print("Attempting to fetch models from OpenRouter...")
    client = OpenRouterAPIClient(api_key="test") # The key is hardcoded in __init__
    models_response = client.make_request('models')
    if models_response:
        print("Successfully fetched models.")
        model_count = len(models_response.get('data', []))
        print(f"Found {model_count} models.")
        if model_count > 0:
            print("First 5 models:")
            for model in models_response['data'][:5]:
                print(f"  - {model.get('id')}")
    else:
        print("Failed to fetch models. Check API key and network connection.")
