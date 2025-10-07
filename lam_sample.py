import re
import os
import requests
import json
import sys

# --- LAM Framework (The "Body") ---
# This is a "tool" the LLM can decide to use.
# It makes a real API call to a public time service.
def get_current_time(timezone: str) -> str:
    """Retrieves the current time for a given timezone."""
    print(f"--- EXECUTING TOOL: get_current_time(timezone={timezone}) ---")
    try:
        response = requests.get(f"http://worldtimeapi.org/api/timezone/{timezone}")
        response.raise_for_status()
        time_data = response.json()
        print(f"--- TOOL EXECUTING: Received full response from time API:\n{json.dumps(time_data, indent=2)} ---")
        return time_data.get('datetime', 'Time not found')
    except requests.exceptions.RequestException as e:
        return f"API Error: {e}"

# A registry of all available tools for the agent to use.
AVAILABLE_TOOLS = {
    "get_current_time": get_current_time,
}


# --- LAM Model (The "Brain") ---
# This function calls a real LLM to process a prompt and decide to call a tool.
def run_llm_agent(user_prompt: str) -> dict | str:
    """
    Calls a real LLM to decide whether to call a tool or respond with text.
    Returns a "tool call" dictionary or a string response.
    """
    print(f"\n--- LLM BRAIN: Processing prompt: '{user_prompt}' ---")

    api_token = "cpk_1c9adce1fd244f5e879cc45afa88c5c4.986b31f04b5056388f96ddf6cbf9f8fe.Osipc4tDlSGc01vCEy2KEuaTdpToFzqs"
    url = "https://llm.chutes.ai/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json",
    }

    system_prompt = """You are an expert assistant AI. Your task is to help users by answering their questions or by using available tools to get information.

When a user asks for information that requires a tool, you must respond ONLY with a JSON object in the following format:
{
  "tool_name": "name_of_the_tool",
  "arguments": {
    "arg1": "value1"
  }
}

Do not add any other text, explanation, or markdown formatting around the JSON.

Here are the available tools:
- Tool: `get_current_time`
  - Description: Retrieves the current time for a specific timezone (e.g., 'Europe/London', 'America/New_York').
  - Arguments:
    - `timezone` (string): The timezone in 'Area/Location' format.

If the user's request does not require a tool, answer their question directly as a helpful assistant."""

    data = {
        "model": "deepseek-ai/DeepSeek-V3.1",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        "max_tokens": 1024,
        "temperature": 0.1  # Lower temperature for more deterministic tool-calling
    }

    try:
        print(f"--- LLM BRAIN: Sending payload:\n{json.dumps(data, indent=2)} ---")
        response = requests.post(url, headers=headers, json=data)
        response.raise_for_status()
        
        response_json = response.json()
        print(f"--- LLM BRAIN: Received full response:\n{json.dumps(response_json, indent=2)} ---")
        llm_output = response_json['choices'][0]['message']['content']
        
        print("--- LLM BRAIN: Received raw output from API. ---")

        # Try to parse the output as a JSON tool call
        try:
            tool_call = json.loads(llm_output)
            if "tool_name" in tool_call and "arguments" in tool_call:
                print(f"--- LLM BRAIN: Decided to call tool '{tool_call['tool_name']}'. ---")
                return tool_call
        except json.JSONDecodeError:
            # If it's not JSON, it's a regular text response
            print("--- LLM BRAIN: Decided no tool was needed. Responding with text. ---")
            return llm_output

    except requests.exceptions.RequestException as e:
        return f"An error occurred with the LLM API: {e}"
    
    return "I'm sorry, I could not process that request."


# --- Agent Executor (Connects the Brain and Body) ---
def execute_lam(user_prompt: str):
    """
    Main execution loop for the LAM system.
    1. Gets a decision from the LLM brain.
    2. If a tool is chosen, it executes it using the framework.
    """
    llm_response = run_llm_agent(user_prompt)

    if isinstance(llm_response, dict): # It's a tool call
        tool_name = llm_response.get("tool_name")
        tool_arguments = llm_response.get("arguments")
        tool_function = AVAILABLE_TOOLS.get(tool_name)

        if tool_function and tool_arguments is not None:
            result = tool_function(**tool_arguments)
            print(f"\n--- FINAL RESULT: The current time is {result}. ---")
        else:
            print(f"--- ERROR: Tool '{tool_name}' not found or arguments missing. ---")
    else: # It's a text response
        print(f"\n--- FINAL RESULT: {llm_response} ---")


# --- Example Usage ---
if __name__ == "__main__":
    execute_lam("What time is it in Europe/London?")
    execute_lam("Tell me a joke.")
