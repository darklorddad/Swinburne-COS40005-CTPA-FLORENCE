import os
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
            "HTTP-Referer": "http://localhost:3000", # Replace with your actual app URL
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


if __name__ == "__main__":
    import json

    # This is a self-contained test for the OpenRouterLAM tool-calling functionality.

    # 1. Define a simple tool and its schema
    def get_current_weather(location: str, unit: str = "celsius") -> str:
        """Get the current weather in a given location."""
        # In a real scenario, this would call a weather API.
        # For this test, we'll return a mock response.
        return f"The weather in {location} is 22 degrees {unit}."

    TOOLS_SCHEMA = [
        {
            "type": "function",
            "function": {
                "name": "get_current_weather",
                "description": "Get the current weather in a given location",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "location": {
                            "type": "string",
                            "description": "The city and state, e.g. San Francisco, CA",
                        },
                        "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]},
                    },
                    "required": ["location"],
                },
            },
        }
    ]

    AVAILABLE_TOOLS = {
        "get_current_weather": get_current_weather,
    }

    # 2. Instantiate the LAM
    lam = OpenRouterLAM()

    # 3. Define a user message to trigger the tool
    user_message = "What's the weather like in London?"
    messages = [{"role": "user", "content": user_message}]

    print(f"User: {user_message}\n")

    # 4. Call the LLM with the tool schema
    try:
        print("Calling LLM to see if it uses a tool...")
        response = lam.call_llm(messages, tools=TOOLS_SCHEMA)
        response_message = response['choices'][0]['message']
        messages.append(response_message)  # extend conversation with assistant's reply

        # 5. Check if the model wants to call a tool
        if response_message.get("tool_calls"):
            print("LLM wants to call a tool.")
            print(json.dumps(response_message["tool_calls"], indent=2))

            # 6. Execute the tool call(s)
            tool_calls = response_message["tool_calls"]
            for tool_call in tool_calls:
                function_name = tool_call['function']['name']
                function_to_call = AVAILABLE_TOOLS[function_name]
                function_args = json.loads(tool_call['function']['arguments'])
                
                print(f"Calling function: {function_name} with args: {function_args}")
                
                function_response = function_to_call(**function_args)
                
                print(f"Function response: {function_response}\n")

                # 7. Send the tool response back to the model
                messages.append(
                    {
                        "tool_call_id": tool_call['id'],
                        "role": "tool",
                        "name": function_name,
                        "content": function_response,
                    }
                )
            
            # Get a new response from the model where it can see the function response
            print("Sending tool response back to LLM for final answer...")
            final_response = lam.call_llm(messages)
            final_message = final_response['choices'][0]['message']['content']
            print(f"\nLLM final response: {final_message}")

        else:
            # The model did not call a tool, just print the response
            print("LLM did not call a tool.")
            print(f"LLM response: {response_message['content']}")

    except requests.exceptions.RequestException as e:
        print(f"An API error occurred: {e}")
