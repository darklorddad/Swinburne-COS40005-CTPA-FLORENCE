import os
import json
import requests
from typing import List, Dict, Any, Literal

from langchain_community.chat_models.openrouter import ChatOpenRouter
from langchain_core.messages import HumanMessage, ToolMessage, AIMessage
from langchain_core.pydantic_v1 import BaseModel, Field
from langchain_core.tools import tool


# API configuration for OpenRouter
API_KEY = "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"
MODEL_NAME = "deepseek/deepseek-chat"

class OpenRouterLAM:
    """
    A Language Agent Model (LAM) using LangChain with OpenRouter for the LLM.
    Supports multi-turn conversations and tool calling.
    """

    def __init__(self, api_key: str = API_KEY, model: str = MODEL_NAME):
        self.api_key = api_key
        self.model = model
        self.llm = ChatOpenRouter(
            model_name=self.model,
            open_router_api_key=self.api_key,
            model_kwargs={
                "headers": {
                    "HTTP-Referer": "http://localhost:3000",
                    "X-Title": "Biotective",
                }
            },
        )

    def call_llm(self, messages: List[Any], tools: List[Any] = None) -> AIMessage:
        """
        Calls the OpenRouter LLM API with the given messages and tools using LangChain.
        """
        bound_model = self.llm
        if tools:
            bound_model = self.llm.bind_tools(tools)

        return bound_model.invoke(messages)


if __name__ == "__main__":
    # This is a self-contained test for the OpenRouterLAM tool-calling functionality using LangChain.

    # 1. Define a simple tool using LangChain's @tool decorator
    class WeatherArgs(BaseModel):
        location: str = Field(description="The city and state, e.g. San Francisco, CA")
        unit: Literal["celsius", "fahrenheit"] = "celsius"

    @tool(args_schema=WeatherArgs)
    def get_current_weather(location: str, unit: str = "celsius") -> str:
        """Get the current weather in a given location."""
        # In a real scenario, this would call a weather API.
        # For this test, we'll return a mock response as a JSON string.
        weather_info = {"location": location, "temperature": "22", "unit": unit}
        return json.dumps(weather_info)

    tools = [get_current_weather]
    available_tools = {t.name: t for t in tools}

    # 2. Instantiate the LAM
    lam = OpenRouterLAM()

    # 3. Define a user message to trigger the tool
    user_message = "What's the weather like in London?"
    messages: list = [HumanMessage(content=user_message)]

    print(f"User: {user_message}\n")

    # 4. Call the LLM with the tools
    try:
        print("Calling LLM to see if it uses a tool...")
        response_message = lam.call_llm(messages, tools=tools)
        messages.append(response_message)  # extend conversation with assistant's reply

        # 5. Check if the model wants to call a tool
        if response_message.tool_calls:
            print("LLM wants to call a tool.")
            print(json.dumps(response_message.tool_calls, indent=2))

            # 6. Execute the tool call(s)
            for tool_call in response_message.tool_calls:
                tool_to_call = available_tools[tool_call["name"]]
                tool_output = tool_to_call.invoke(tool_call["args"])
                print(f"Calling function: {tool_call['name']} with args: {tool_call['args']}")
                print(f"Function response: {tool_output}\n")

                # 7. Send the tool response back to the model
                messages.append(
                    ToolMessage(content=tool_output, tool_call_id=tool_call["id"])
                )
            
            # Get a new response from the model where it can see the function response
            print("Sending tool response back to LLM for final answer...")
            final_response = lam.call_llm(messages)
            print(f"\nLLM final response: {final_response.content}")

        else:
            # The model did not call a tool, just print the response
            print("LLM did not call a tool.")
            print(f"LLM response: {response_message.content}")

    except requests.exceptions.HTTPError as e:
        print(f"An API error occurred: {e}")
        print(f"Response body: {e.response.text}")
    except requests.exceptions.RequestException as e:
        print(f"An API error occurred: {e}")
