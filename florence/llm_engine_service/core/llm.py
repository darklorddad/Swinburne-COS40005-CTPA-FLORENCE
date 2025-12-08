from langchain_openai import ChatOpenAI
from ..config import settings

def get_llm_client(temperature: float = 0.0):
    """
    Returns a configured LangChain Chat Model.
    """
    return ChatOpenAI(
        base_url=settings.LLM_BASE_URL,
        api_key=settings.LLM_API_KEY,
        model=settings.LLM_MODEL,
        temperature=temperature,
        max_tokens=2000,
        # Essential for Vercel to avoid hanging connections
        timeout=30, 
        max_retries=1,
    )
