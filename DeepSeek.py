import os
import requests
import json
import sys

# Retrieve the API token from an environment variable for security
api_token = "cpk_1c9adce1fd244f5e879cc45afa88c5c4.986b31f04b5056388f96ddf6cbf9f8fe.Osipc4tDlSGc01vCEy2KEuaTdpToFzqs"

# Check if the API token is set
if not api_token:
    raise ValueError("The CHUTES_API_TOKEN environment variable is not set.")

# The API endpoint URL
url = "https://llm.chutes.ai/v1/chat/completions"

# The headers for the request, including Authorization and Content-Type
headers = {
    "Authorization": f"Bearer {api_token}",
    "Content-Type": "application/json",
}

# The JSON data payload for the request
data = {
    "model": "deepseek-ai/DeepSeek-V3.1",
    "messages": [
        {
            "role": "user",
            "content": "Tell me a 250 word story."
        }
    ],
    "stream": True,
    "max_tokens": 1024,
    "temperature": 0.7
}

try:
    # Make the POST request with streaming enabled
    with requests.post(url, headers=headers, json=data, stream=True) as response:
        # Check if the request was successful
        response.raise_for_status()

        print("Successfully connected to the API. Here is the generated story:")
        print("-" * 60)

        # Iterate over the response line by line to handle SSE
        for line in response.iter_lines():
            if line:
                # Decode the line from bytes to a string
                decoded_line = line.decode('utf-8')

                # Check if the line is a data line from the SSE stream
                if decoded_line.startswith('data:'):
                    # Remove the "data: " prefix
                    json_str = decoded_line[len('data:'):].strip()

                    # Handle the end-of-stream signal
                    if json_str == '[DONE]':
                        break

                    try:
                        # Parse the JSON string
                        chunk = json.loads(json_str)
                        # Get the content from the first choice's delta
                        delta = chunk['choices'][0]['delta']
                        
                        # Check if 'content' exists in the delta
                        if 'content' in delta and delta['content'] is not None:
                            # Print the content and flush the output to show it immediately
                            print(delta['content'], end='', flush=True)

                    except (json.JSONDecodeError, KeyError) as e:
                        # This can happen if the JSON is malformed or the structure is unexpected
                        # For simplicity, we'll just skip these lines in this example
                        pass

        print("\n" + "-" * 60)
        print("Stream finished.")

except requests.exceptions.RequestException as e:
    print(f"An error occurred: {e}", file=sys.stderr)
except ValueError as e:
    print(f"Configuration error: {e}", file=sys.stderr)