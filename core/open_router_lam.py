import os
import json
import requests
from typing import List, Dict, Any

# API configuration for OpenRouter
API_KEY = "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"
API_URL = "https://openrouter.ai/api/v1/chat/completions"
MODEL_NAME = "deepseek/deepseek-chat"

class OpenRouterLAM:
    """
    A Language Agent Model (LAM) using OpenRouter for the LLM.
    Supports multi-turn conversations and tool calling.
    """

    def __init__(self, api_key: str = API_KEY, model: str = MODEL_NAME):
        self.api_key = api_key
        self.model = model
        self.api_url = API_URL

    def call_llm(self, messages: List[Dict[str, Any]], tools: List[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Calls the OpenRouter LLM API with the given messages and tools.
        """
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": "http://localhost:3000",
            "X-Title": "Biotective",
        }
        
        payload = {
            "model": self.model,
            "messages": messages,
        }

        if tools:
            payload["tools"] = tools
            payload["tool_choice"] = "auto"

        response = requests.post(self.api_url, headers=headers, data=json.dumps(payload))
        response.raise_for_status()  # Raise an exception for bad status codes
        return response.json()


if __name__ == "__main__":
    # This is a self-contained test for the OpenRouterLAM basic chat functionality.

    # 1. Instantiate the LAM
    lam = OpenRouterLAM()

    # 2. Define a user message
    user_message = "What is the meaning of life?"
    messages = [{"role": "user", "content": user_message}]

    print(f"User: {user_message}\n")

    # 3. Call the LLM without tools
    try:
        print("Calling LLM...")
        response = lam.call_llm(messages)
        response_message = response['choices'][0]['message']
        
        print("LLM response:")
        print(response_message['content'])

    except requests.exceptions.HTTPError as e:
        print(f"An API error occurred: {e}")
        print(f"Response body: {e.response.text}")
    except requests.exceptions.RequestException as e:
        print(f"An API error occurred: {e}")
