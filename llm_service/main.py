from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List

# Assuming open_router_lam.py is in the same directory.
# The summary for open_router_lam.py does not show its __init__,
# so we assume it can be instantiated without arguments.
from open_router_lam import OpenRouterLAM

app = FastAPI(
    title="LLM Service",
    description="A proxy service to interact with a Large Language Model.",
)

# Initialize the LAM instance globally for reuse across requests
lam = OpenRouterLAM()

class ChatRequest(BaseModel):
    prompt: str

class ChatResponse(BaseModel):
    response: str

@app.post("/chat", response_model=ChatResponse)
async def chat_with_llm(request: ChatRequest):
    """
    Receives a prompt and returns the LLM's response.
    """
    if not request.prompt:
        raise HTTPException(status_code=400, detail="Prompt cannot be empty.")

    try:
        # The call_llm method expects a list of messages in OpenAI format
        messages = [
            {"role": "user", "content": request.prompt}
        ]
        
        ai_message = lam.call_llm(messages)
        
        response_content = ai_message.content

        return {"response": response_content}
    except Exception as e:
        print(f"An error occurred in /chat endpoint: {e}")
        raise HTTPException(status_code=500, detail="An error occurred while processing your request.")

if __name__ == "__main__":
    import uvicorn
    # Run on a different port to avoid conflict with the main Supabase API
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
