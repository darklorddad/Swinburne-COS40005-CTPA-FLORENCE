import requests
import json
from typing import List, Dict, Any, Callable

# --- Configuration from AI-Integration-branch\DeepSeek.py for reference ---
# In a production application, these would be loaded from environment variables
# or a secure configuration management system.
API_TOKEN = "cpk_1c9adce1fd244f5e879cc45afa88c5c4.986b31f04b5056388f96ddf6cbf9f8fe.Osipc4tDlSGc01vCEy2KEuaTdpToFzqs" # Consider moving this to an environment variable for security.
API_URL = "https://llm.chutes.ai/v1/chat/completions"
MODEL_NAME = "deepseek-ai/DeepSeek-V3.1"
# -------------------------------------------------------------------------

class ChutesLAM:
    """
    A Language Agent Model (LAM) proof-of-concept using Chutes.ai for the LLM.
    Supports multi-turn conversations and tool calling.
    """
    def __init__(self, tools_schema: List[Dict[str, Any]], available_tools: Dict[str, Callable]):
        self.conversation_history: List[Dict[str, Any]] = []
        self.tools_schema = tools_schema
        self.available_tools = available_tools

        # Add an initial system message to guide the LLM on tool usage and output interpretation
        if self.tools_schema:
            self.conversation_history.append(
                {
                    "role": "system",
                    "content": (
                        "You are a helpful AI assistant with access to a tool `get_patient_glucose_level`. "
                        "When a user asks for a patient's glucose level, you will use this tool. "
                        "After the tool executes, its output will be provided to you in a 'tool' message. "
                        "The `content` of this 'tool' message will be a JSON string. You MUST parse this JSON string. "
                        "If the parsed JSON contains an 'error' field, your response MUST be ONLY the error message from that field. "
                        "If the parsed JSON contains 'glucose_level' and NO 'error' field, your response MUST be ONLY: "
                        "'Patient [patient_id]'s glucose level is [glucose_level] [unit].' "
                        "For example, if the tool message content is `{\"patient_id\": \"patient123\", \"glucose_level\": 87.0, \"unit\": \"mg/dL\"}`, "
                        "your response MUST be: 'Patient patient123's glucose level is 87.0 mg/dL.' "
                        "Do NOT add any other text, apologies, or conversational filler. Be direct and factual."
                    )
                }
            )

    def _call_llm(self, messages: List[Dict[str, Any]], tools: List[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Makes a call to the Chutes.ai LLM API.
        """
        headers = {
            "Authorization": f"Bearer {API_TOKEN}",
            "Content-Type": "application/json"
        }
        payload = {
            "model": MODEL_NAME,
            "messages": messages,
            "stream": False, # For PoC simplicity, not using streaming for tool calls
            "max_tokens": 1024,
        }
        if tools:
            payload["tools"] = tools
            payload["tool_choice"] = "auto" # Allow LLM to decide if it wants to use tools

        try:
            print(f"\nDEBUG: Sending messages to LLM: {json.dumps(messages, indent=2)}")
            if tools:
                print(f"DEBUG: With tools: {json.dumps(tools, indent=2)}")
            response = requests.post(API_URL, headers=headers, json=payload)
            response.raise_for_status() # Raise an exception for HTTP errors (4xx or 5xx)
            llm_raw_response = response.json()
            print(f"DEBUG: Raw LLM response: {json.dumps(llm_raw_response, indent=2)}")
            return llm_raw_response
        except requests.exceptions.RequestException as e:
            print(f"Error calling LLM: {e}")
            return {"error": str(e)}

    def chat(self, user_message: str) -> str:
        """
        Processes a user message, interacts with the LLM, handles tool calls,
        and maintains conversation history.
        """
        # Add user message to history
        self.conversation_history.append({"role": "user", "content": user_message})

        # First LLM call: user message + available tools
        llm_response = self._call_llm(self.conversation_history, self.tools_schema)

        if "error" in llm_response:
            return f"An error occurred: {llm_response['error']}"

        assistant_message_content = ""
        tool_calls = []

        # Parse LLM's response for content and tool calls
        for choice in llm_response.get("choices", []):
            message = choice.get("message", {})
            if message.get("content"):
                assistant_message_content += message["content"]
            if message.get("tool_calls"):
                tool_calls.extend(message["tool_calls"])

        # If the LLM requested tool calls, execute them
        if tool_calls:
            print(f"DEBUG: LLM requested tool calls: {tool_calls}")
            
            # Add the assistant's tool_calls message to history.
            # We intentionally do NOT add assistant_message_content here if tool_calls are present,
            # as the final response should come after tool execution.
            self.conversation_history.append(
                {
                    "role": "assistant",
                    "tool_calls": tool_calls,
                }
            )

            tool_outputs = []
            for tool_call in tool_calls:
                function_name = tool_call["function"]["name"]
                # Arguments are typically JSON strings
                function_args = json.loads(tool_call["function"]["arguments"])
                tool_call_id = tool_call["id"]

                if function_name in self.available_tools:
                    print(f"DEBUG: Executing tool: {function_name} with args: {function_args}")
                    try:
                        tool_result = self.available_tools[function_name](**function_args)
                        tool_outputs.append(
                            {
                                "tool_call_id": tool_call_id,
                                "output": tool_result,
                            }
                        )
                    except Exception as e:
                        tool_outputs.append(
                            {
                                "tool_call_id": tool_call_id,
                                "output": json.dumps({"error": f"Tool execution failed: {e}"}),
                            }
                        )
                else:
                    tool_outputs.append(
                        {
                            "tool_call_id": tool_call_id,
                            "output": json.dumps({"error": f"Tool '{function_name}' not found."}),
                        }
                    )
            
            print(f"DEBUG: Tool outputs: {json.dumps(tool_outputs, indent=2)}")

            # Add tool outputs to history as individual messages
            for tool_output in tool_outputs:
                self.conversation_history.append(
                    {
                        "role": "tool",
                        "tool_call_id": tool_output["tool_call_id"],
                        "content": tool_output["output"],
                    }
                )

            # Second LLM call: user message + tool outputs to get a final response
            # Crucially, we do NOT pass tools_schema here, as the LLM's job is now to summarise the tool output.
            print(f"DEBUG: Calling LLM again with tool outputs for final response (without tools).")
            second_llm_response = self._call_llm(self.conversation_history) # Removed self.tools_schema

            if "error" in second_llm_response:
                return f"An error occurred during tool output processing: {second_llm_response['error']}"

            final_assistant_message_content = ""
            for choice in second_llm_response.get("choices", []):
                message = choice.get("message", {})
                if message.get("content"):
                    final_assistant_message_content += message["content"]
            
            if final_assistant_message_content:
                self.conversation_history.append({"role": "assistant", "content": final_assistant_message_content})
                return final_assistant_message_content
            else:
                return "The AI did not provide a final response after tool execution."
        else: # No tool calls were made in the first LLM response
            # If the LLM provided a direct response (without tool calls), add it to history
            if assistant_message_content:
                self.conversation_history.append({"role": "assistant", "content": assistant_message_content})
                return assistant_message_content
            else:
                # If no tool calls and no direct content, something went wrong or LLM was silent
                return "No response from AI."
