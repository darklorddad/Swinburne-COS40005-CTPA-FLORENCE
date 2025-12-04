"""
DeepSeek API integration service for LLM-powered chat responses.
"""
import httpx
from typing import List, Optional
from config import settings
from models.chat import (
    LLMMessage,
    LLMRequest,
    LLMResponse,
)


class LLMService:
    """Service for interacting with the LLM API."""

    def __init__(self):
        """Initialize the LLM service."""
        self.base_url = settings.llm_base_url
        self.api_key = settings.llm_api_key
        self.model = settings.llm_model
        self.temperature = settings.llm_temperature
        self.max_tokens = settings.llm_max_tokens

    def _get_headers(self) -> dict:
        """Get HTTP headers for LLM API requests."""
        return {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.api_key}",
            "HTTP-Referer": "https://florence-health.app",
            "X-Title": "Florence Health",
        }

    async def chat_completion(
        self,
        messages: List[LLMMessage],
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
    ) -> str:
        """
        Send a chat completion request to LLM API.

        Args:
            messages: List of conversation messages
            temperature: Optional override for temperature (0.0-1.0)
            max_tokens: Optional override for max tokens

        Returns:
            The assistant's response content

        Raises:
            httpx.HTTPError: If API request fails
            Exception: If response parsing fails
        """
        request_data = LLMRequest(
            model=self.model,
            messages=messages,
            temperature=temperature or self.temperature,
            max_tokens=max_tokens or self.max_tokens,
            stream=False,
        )

        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f"{self.base_url}/chat/completions",
                    headers=self._get_headers(),
                    json=request_data.model_dump(exclude_none=True),
                    timeout=60.0,
                )

                response.raise_for_status()

                data = response.json()
                llm_response = LLMResponse(**data)

                if not llm_response.choices or len(llm_response.choices) == 0:
                    raise Exception("No response choices returned from LLM API")

                return llm_response.choices[0].message.content

            except httpx.HTTPStatusError as e:
                raise Exception(f"LLM API error: {e.response.status_code} - {e.response.text}")
            except httpx.RequestError as e:
                raise Exception(f"Network error calling LLM API: {str(e)}")
            except Exception as e:
                raise Exception(f"Error processing LLM response: {str(e)}")

    def build_system_prompt(self, health_context_formatted: str) -> str:
        """
        Build the system prompt with health context.

        Args:
            health_context_formatted: Formatted health context string

        Returns:
            Complete system prompt for the LLM
        """
        return f"""You are FLORENCE, a friendly AI health assistant for chronic disease management.

Patient's recent health context:
{health_context_formatted}

Your role:
- Answer questions about their health data
- Provide guidance and support
- Explain chronic disease management concepts
- Offer personalized tips based on their data
- Be warm, encouraging, and non-judgmental

Important:
- Never diagnose or provide medical advice
- Encourage them to consult healthcare providers for concerns
- Reference their actual data when relevant
- Keep responses concise and clear
- Be empathetic and supportive"""



# Singleton instance
_llm_service: Optional[LLMService] = None


def get_llm_service() -> LLMService:
    """Get or create the singleton LLMService instance."""
    global _llm_service
    if _llm_service is None:
        _llm_service = LLMService()
    return _llm_service
