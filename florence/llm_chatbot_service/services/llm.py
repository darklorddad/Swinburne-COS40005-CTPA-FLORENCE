"""
DeepSeek API integration service for LLM-powered chat responses.
"""
from typing import List, Optional
from datetime import datetime, timedelta, timezone
from langchain_openai import ChatOpenAI
from langchain_core.messages import BaseMessage
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from config import settings


class LLMService:
    """Service for interacting with the LLM API via LangChain."""

    def __init__(self):
        """Initialize the LangChain LLM service."""
        # Initialize ChatOpenAI pointing to OpenRouter/DeepSeek
        self.llm = ChatOpenAI(
            base_url=settings.llm_base_url,
            api_key=settings.llm_api_key,
            model=settings.llm_model,
            temperature=settings.llm_temperature or 0.7,
        )

    async def chat_completion(
        self,
        health_context: str,
        history: List[BaseMessage],
        current_message: str,
        local_time: Optional[str] = None,
        timezone_offset: Optional[int] = None
    ) -> str:
        """
        Generate a response using LangChain.
        """
        try:
            # Format timezone instructions dynamically if provided by client
            tz_info = ""
            if local_time and timezone_offset is not None:
                sign = "+" if timezone_offset >= 0 else ""
                tz_info = f"\nNote: All data timestamps in the context are in UTC. The patient's local time zone is UTC{sign}{timezone_offset}.\nThe patient's current local device time is {local_time}. Please adjust any data timestamps to match the patient's local time when discussing them."

            # Define the Prompt Template
            prompt = ChatPromptTemplate.from_messages([
                ("system", """You are FLORENCE, a friendly AI health assistant for chronic disease management.

Patient's recent health context:
{health_context}{tz_info}

Your role:
- Answer questions about their health data
- Provide guidance and support
- Explain chronic disease management concepts
- Offer personalized tips based on their data
- Be warm, encouraging, and non-judgmental

Important:
- MEDICAL GUARDRAILS: You are a guidance tool, not a doctor. You may provide lifestyle, dietary, timing, physical activity, and sleep advice. You MUST NOT diagnose conditions, prescribe new medications, or recommend changes to medication dosages (e.g., never say "take an extra unit of insulin").
- Always use the patient's preferred units (e.g., mmol/L vs mg/dL) as indicated in their profile settings.
- When evaluating if a reading is high or low, strictly use the patient's personalized thresholds provided in the context, NOT general defaults.
- Never diagnose or provide medical advice
- Encourage them to consult healthcare providers for concerns
- Reference their actual data when relevant
- Keep responses concise and clear
- Be empathetic and supportive"""),
                MessagesPlaceholder(variable_name="history"),
                ("human", "{input}")
            ])

            # Create the chain
            chain = prompt | self.llm

            # Invoke the chain
            response = await chain.ainvoke({
                "health_context": health_context,
                "tz_info": tz_info,
                "history": history,
                "input": current_message
            })

            return response.content

        except Exception as e:
            raise Exception(f"LangChain Error: {str(e)}")



# Singleton instance
_llm_service: Optional[LLMService] = None


def get_llm_service() -> LLMService:
    """Get or create the singleton LLMService instance."""
    global _llm_service
    if _llm_service is None:
        _llm_service = LLMService()
    return _llm_service
