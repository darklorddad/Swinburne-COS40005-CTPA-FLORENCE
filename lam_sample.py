import re
import random
import os
import requests
import json
import sys

# --- LAM Framework (The "Body") ---
# This is a "tool" the LLM can decide to use.
# In a real system, this would interact with your Supabase database.
def get_patient_risk_level(patient_id: int) -> str:
    """Retrieves the risk level for a given patient ID."""
    print(f"--- EXECUTING TOOL: get_patient_risk_level(patient_id={patient_id}) ---")
    # In a real app, you'd query your database. Here, we simulate it.
    risk_levels = ["LOW", "MEDIUM", "HIGH"]
    return random.choice(risk_levels)

# A registry of all available tools for the agent to use.
AVAILABLE_TOOLS = {
    "get_patient_risk_level": get_patient_risk_level,
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

    system_prompt = """You are an expert medical assistant AI. Your task is to help users by answering their questions or by using available tools to get information.

When a user asks for information that requires a tool, you must respond ONLY with a JSON object in the following format:
{
  "tool_name": "name_of_the_tool",
  "arguments": {
    "arg1": "value1"
  }
}

Do not add any other text, explanation, or markdown formatting around the JSON.

Here are the available tools:
- Tool: `get_patient_risk_level`
  - Description: Retrieves the current risk level ('LOW', 'MEDIUM', or 'HIGH') for a specific patient.
  - Arguments:
    - `patient_id` (integer): The unique identifier for the patient.

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
        response = requests.post(url, headers=headers, json=data)
        response.raise_for_status()
        
        response_json = response.json()
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
            print(f"\n--- FINAL RESULT: The risk level is {result}. ---")
        else:
            print(f"--- ERROR: Tool '{tool_name}' not found or arguments missing. ---")
    else: # It's a text response
        print(f"\n--- FINAL RESULT: {llm_response} ---")


# --- Example Usage ---
if __name__ == "__main__":
    execute_lam("What is the risk level for patient 452?")
    execute_lam("Hello, how are you today?")
