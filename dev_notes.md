# Development Notes

## 2025-10-30

- **Objective**: Switch to OpenRouter for tool calling.
- **Model**: `deepseek/deepseek-chat-v3.1:free`
- **API Key**: `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`

### Changes Made

- Created `core/open_router_lam.py` to encapsulate interaction with the OpenRouter API.
  - This file contains the new API key, URL, and model.
  - It includes an `OpenRouterLAM` class with a `call_llm` method that supports tool calling.
- Created this `dev_notes.md` file to track progress.

### Next Steps

- Integrate `OpenRouterLAM` into the application logic.
- Implement the full tool-calling loop (handling model requests to call tools, executing them, and returning results).
- Replace any existing LLM call sites with the new `OpenRouterLAM`.
- Test tool calling functionality with a simple tool (e.g., `core.tools.get_patient_glucose_level`).
