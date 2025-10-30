import os
import requests
from typing import List, Dict, Any

# API configuration for OpenRouter
API_KEY = "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"
API_URL = "https://openrouter.ai/api/v1/chat/completions"
MODEL_NAME = "deepseek/deepseek-chat-v3.1:free"

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
            "HTTP-Referer": "http://localhost", # Replace with your actual app URL
            "X-Title": "Biotective", # Replace with your app name
        }
        
        payload = {
            "model": self.model,
            "messages": messages,
        }

        if tools:
            payload["tools"] = tools
            payload["tool_choice"] = "auto"

        response = requests.post(self.api_url, headers=headers, json=payload)
        response.raise_for_status()  # Raise an exception for bad status codes
        return response.json()
