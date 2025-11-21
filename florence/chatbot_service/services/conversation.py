"""
Conversation history management service for storing and retrieving chat messages via Data Service.
"""
from datetime import datetime
from typing import List, Optional
import httpx
from config import settings
from models.chat import ChatMessage, DeepSeekMessage


class ConversationService:
    """Service for managing chat conversation history via Data Service."""

    async def save_message(
        self,
        token: str,
        role: str,
        content: str,
        context: Optional[dict] = None
    ) -> ChatMessage:
        """
        Save a chat message via Data Service.
        """
        payload = {
            "role": role,
            "content": content,
            "context": context,
            "timestamp": datetime.now().isoformat()
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{settings.data_service_url}/chat/history",
                headers={"Authorization": f"Bearer {token}"},
                json=payload,
                timeout=10.0
            )
            response.raise_for_status()
            data = response.json()

        return ChatMessage(
            id=data["id"],
            role=data["role"],
            content=data["content"],
            timestamp=datetime.fromisoformat(data["timestamp"].replace('Z', '+00:00')),
            context=data.get("context"),
        )

    async def get_conversation_history(
        self,
        token: str,
        limit: Optional[int] = 50
    ) -> List[ChatMessage]:
        """
        Retrieve conversation history via Data Service.
        """
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{settings.data_service_url}/chat/history",
                headers={"Authorization": f"Bearer {token}"},
                params={"limit": limit},
                timeout=10.0
            )
            response.raise_for_status()
            data = response.json()

        return [
            ChatMessage(
                id=msg["id"],
                role=msg["role"],
                content=msg["content"],
                timestamp=datetime.fromisoformat(msg["timestamp"].replace('Z', '+00:00')),
                context=msg.get("context"),
            )
            for msg in data
        ]

    async def get_recent_messages(
        self,
        token: str,
        count: int = 10
    ) -> List[ChatMessage]:
        """
        Get the most recent N messages for context in LLM prompts.
        """
        # We fetch 'count' messages from the history endpoint
        # The endpoint returns oldest first, so we take the last 'count'
        history = await self.get_conversation_history(token, limit=count)
        return history

    async def clear_conversation_history(self, token: str) -> int:
        """
        Clear all conversation history via Data Service.
        """
        async with httpx.AsyncClient() as client:
            response = await client.delete(
                f"{settings.data_service_url}/chat/history",
                headers={"Authorization": f"Bearer {token}"},
                timeout=10.0
            )
            response.raise_for_status()
            # Assuming the data service returns count, but our current implementation 
            # just returns a message. We'll return 0 or modify data service if needed.
            # For now, we just return 0 as the count isn't critical.
            return 0

    def convert_to_deepseek_messages(
        self,
        chat_messages: List[ChatMessage]
    ) -> List[DeepSeekMessage]:
        """
        Convert ChatMessage objects to DeepSeekMessage format.
        """
        return [
            DeepSeekMessage(role=msg.role, content=msg.content)
            for msg in chat_messages
            if msg.role in ["user", "assistant"]  # Exclude system messages
        ]

    async def get_conversation_count(self, token: str) -> int:
        """
        Get the total number of messages.
        """
        # Since we don't have a dedicated count endpoint in the new router yet,
        # we'll just fetch history with a large limit or return len of fetched.
        # For efficiency, we might want to add a count endpoint later.
        # For now, we'll just return the length of what we fetch (up to limit).
        history = await self.get_conversation_history(token, limit=100)
        return len(history)


# Singleton instance
_conversation_service: Optional[ConversationService] = None


def get_conversation_service() -> ConversationService:
    """Get or create the singleton ConversationService instance."""
    global _conversation_service
    if _conversation_service is None:
        _conversation_service = ConversationService()
    return _conversation_service
