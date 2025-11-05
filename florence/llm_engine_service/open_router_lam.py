import os
import json
import requests
from typing import List, Dict, Any, Literal

from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, ToolMessage, AIMessage
from pydantic.v1 import BaseModel, Field
from langchain_core.tools import tool

import langchain
langchain.verbose = False # type: ignore
langchain.debug = False # type: ignore
langchain.llm_cache = None # type: ignore


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
        self.llm = ChatOpenAI(
            model=self.model,
            api_key=self.api_key,
            base_url="https://openrouter.ai/api/v1",
            default_headers={
                "HTTP-Referer": "http://localhost:3000",
                "X-Title": "Biotective",
            },
            verbose=True,
        )

    def call_llm(self, messages: List[Any], tools: List[Any] = None) -> AIMessage:
        """
        Calls the OpenRouter LLM API with the given messages and tools using LangChain.
        """
        print(f"\n--- Sending to LLM ---\n{messages}\n")
        bound_model = self.llm
        if tools:
            bound_model = self.llm.bind_tools(tools)

        response = bound_model.invoke(messages)

        print(f"\n--- Received from LLM ---\n{response}\n")

        return response


if __name__ == "__main__":
    # This is a self-contained test for the OpenRouterLAM tool-calling functionality using LangChain.

    # 1. Define a simple tool using LangChain's @tool decorator
    print("--- STEP 1: Tool Definition ---")
    class WeatherArgs(BaseModel):
        location: str = Field(description="The city and state, e.g. San Francisco, CA")
        unit: Literal["celsius", "fahrenheit"] = "celsius"

    @tool(args_schema=WeatherArgs)
    def get_current_weather(location: str, unit: str = "celsius") -> str:
        """Get the current weather in a given location."""
        # In a real scenario, this would call a weather API.
        # For this test, we'll return a mock response as a JSON string.
        print(f"--- TOOL: Executing get_current_weather(location='{location}', unit='{unit}') ---")
        weather_info = {"location": location, "temperature": "22", "unit": unit}
        return json.dumps(weather_info)

    tools = [get_current_weather]
    print(f"Defined tool: {tools[0].name}\n")
    available_tools = {t.name: t for t in tools}

    # 2. Instantiate the LAM
    print("--- STEP 2: Instantiate LAM ---")
    lam = OpenRouterLAM()
    print("OpenRouterLAM instantiated.\n")

    # 3. Define a user message to trigger the tool
    user_message = "What's the weather like in London?"
    messages: list = [HumanMessage(content=user_message)]
    print("--- STEP 3: Initial User Message ---")
    print(f"User: {user_message}\n")

    # 4. Call the LLM with the tools
    try:
        print("--- STEP 4: First LLM Call (with tools) ---")
        print("Calling LLM to see if it uses a tool...")
        response_message = lam.call_llm(messages, tools=tools)

        messages.append(response_message)  # extend conversation with assistant's reply

        # 5. Check if the model wants to call a tool
        print("\n--- STEP 5: Check for Tool Call ---")
        if response_message.tool_calls:
            print("LLM decided to call a tool.")
            print(f"Parsed tool calls: {json.dumps(response_message.tool_calls, indent=2)}\n")

            # 6. Execute the tool call(s)
            print("--- STEP 6: Execute Tool Call(s) ---")
            for tool_call in response_message.tool_calls:
                tool_to_call = available_tools[tool_call["name"]]
                tool_output = tool_to_call.invoke(tool_call["args"])
                # The print inside the tool function shows execution details.
                print(f"Tool '{tool_call['name']}' returned: {tool_output}\n")

                # 7. Send the tool response back to the model
                print("--- STEP 7: Append Tool Result to Messages ---")
                tool_message = ToolMessage(content=tool_output, tool_call_id=tool_call["id"])
                messages.append(tool_message)
                print("Appended tool result.\n")
            
            # Get a new response from the model where it can see the function response
            print("--- STEP 8: Second LLM Call (with tool results) ---")
            print("Sending tool response back to LLM for final answer...")
            final_response = lam.call_llm(messages)
            print(f"\nLLM final answer: {final_response.content}")

        else:
            # The model did not call a tool, just print the response
            print("LLM did not call a tool.")
            print(f"LLM response: {response_message.content}")

    except requests.exceptions.HTTPError as e:
        print(f"An API error occurred: {e}")
        print(f"Response body: {e.response.text}")
    except requests.exceptions.RequestException as e:
        print(f"An API error occurred: {e}")
