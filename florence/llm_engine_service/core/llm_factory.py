from langchain_openai import ChatOpenAI
from ..config import settings

class LLMFactory:
    """
    Factory to create LLM instances with specific configurations.
    """
    
    @staticmethod
    def create(
        temperature: float = None, 
        model: str = None,
        max_tokens: int = None
    ) -> ChatOpenAI:
        return ChatOpenAI(
            base_url=settings.LLM_BASE_URL,
            api_key=settings.LLM_API_KEY,
            model=model or settings.LLM_MODEL,
            temperature=temperature if temperature is not None else settings.LLM_TEMPERATURE,
            max_tokens=max_tokens or settings.LLM_MAX_TOKENS,
            # Timeout is critical for serverless (Vercel) to avoid hanging
            timeout=30, 
            max_retries=1,
        )
