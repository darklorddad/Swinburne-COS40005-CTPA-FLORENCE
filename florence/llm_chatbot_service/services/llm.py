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
        current_message: str
    ) -> str:
        """
        Generate a response using LangChain.
        """
        try:
            # Define the Prompt Template
            prompt = ChatPromptTemplate.from_messages([
                ("system", """You are FLORENCE, a friendly AI health assistant for chronic disease management.

Patient's recent health context:
{health_context}

Note: The patient is located in Malaysia (UTC+8). Please automatically adjust any UTC timestamps found in their data to Malaysia time (+8 Hours) when discussing dates and times with them!
The current time in Malaysia is {current_time}.

Your role:
- Answer questions about their health data
- Provide guidance and support
- Explain chronic disease management concepts
- Offer personalized tips based on their data
- Be warm, encouraging, and non-judgmental

Important:
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

            malaysia_time = datetime.now(timezone.utc) + timedelta(hours=8)
            current_time_str = malaysia_time.strftime("%A, %B %d, %Y %I:%M %p")

            # Invoke the chain
            response = await chain.ainvoke({
                "health_context": health_context,
                "current_time": current_time_str,
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
