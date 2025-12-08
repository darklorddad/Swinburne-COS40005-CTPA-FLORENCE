from langchain_openai import ChatOpenAI
from ..config import settings

class LLMFactory:
    """
    Factory to create LLM instances.
    Uses Provider Defaults unless overridden by ENV vars or specific arguments.
    """
    
    @staticmethod
    def create(
        temperature: float = None, 
        model: str = None,
        max_tokens: int = None
    ) -> ChatOpenAI:
        # Priority:
        # 1. Argument passed to this function (Code override)
        # 2. Environment Variable (Config override)
        # 3. None (Provider Default)
        
        final_temp = temperature if temperature is not None else settings.LLM_TEMPERATURE
        final_tokens = max_tokens if max_tokens is not None else settings.LLM_MAX_TOKENS
        final_model = model or settings.LLM_MODEL

        return ChatOpenAI(
            base_url=settings.LLM_BASE_URL,
            api_key=settings.LLM_API_KEY,
            model=final_model,
            temperature=final_temp,
            max_tokens=final_tokens,
            # Timeout is critical for serverless (Vercel) to avoid hanging
            timeout=30, 
            max_retries=1,
        )
