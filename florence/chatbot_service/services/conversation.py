"""
Conversation history management service for storing and retrieving chat messages.
"""
from datetime import datetime
from typing import List, Optional
import uuid
from supabase import create_client, Client
from config import settings
from models.chat import ChatMessage, DeepSeekMessage


class ConversationService:
    """Service for managing chat conversation history."""

    def __init__(self):
        """Initialize the conversation service with Supabase client."""
        self.supabase: Client = create_client(
            settings.supabase_url,
            settings.supabase_service_key
        )
        self.table_name = "patient_chat_history"

    async def save_message(
        self,
        patient_id: int,
        role: str,
        content: str,
        context: Optional[dict] = None
    ) -> ChatMessage:
        """
        Save a chat message to the database.

        Args:
            patient_id: Patient ID
            role: Message role ('user' or 'assistant')
            content: Message content
            context: Optional health context snapshot

        Returns:
            ChatMessage object with generated ID
        """
        message_id = str(uuid.uuid4())
        timestamp = datetime.now()

        message_data = {
            "id": message_id,
            "patient_id": patient_id,
            "role": role,
            "content": content,
            "timestamp": timestamp.isoformat(),
            "context": context,
        }

        self.supabase.table(self.table_name).insert(message_data).execute()

        return ChatMessage(
            id=message_id,
            role=role,
            content=content,
            timestamp=timestamp,
            context=context,
        )

    async def get_conversation_history(
        self,
        patient_id: int,
        limit: Optional[int] = 50
    ) -> List[ChatMessage]:
        """
        Retrieve conversation history for a patient.

        Args:
            patient_id: Patient ID
            limit: Maximum number of messages to retrieve (default: 50)

        Returns:
            List of ChatMessage objects, ordered by timestamp (oldest first)
        """
        response = (
            self.supabase.table(self.table_name)
            .select("*")
            .eq("patient_id", patient_id)
            .order("timestamp", desc=False)
            .limit(limit)
            .execute()
        )

        return [
            ChatMessage(
                id=msg["id"],
                role=msg["role"],
                content=msg["content"],
                timestamp=datetime.fromisoformat(msg["timestamp"]),
                context=msg.get("context"),
            )
            for msg in response.data
        ]

    async def get_recent_messages(
        self,
        patient_id: int,
        count: int = 10
    ) -> List[ChatMessage]:
        """
        Get the most recent N messages for context in LLM prompts.

        Args:
            patient_id: Patient ID
            count: Number of recent messages to retrieve

        Returns:
            List of ChatMessage objects, ordered by timestamp (oldest first)
        """
        response = (
            self.supabase.table(self.table_name)
            .select("*")
            .eq("patient_id", patient_id)
            .order("timestamp", desc=True)
            .limit(count)
            .execute()
        )

        # Reverse to get chronological order (oldest first)
        messages = [
            ChatMessage(
                id=msg["id"],
                role=msg["role"],
                content=msg["content"],
                timestamp=datetime.fromisoformat(msg["timestamp"]),
                context=msg.get("context"),
            )
            for msg in reversed(response.data)
        ]

        return messages

    async def clear_conversation_history(self, patient_id: int) -> int:
        """
        Clear all conversation history for a patient.

        Args:
            patient_id: Patient ID

        Returns:
            Number of messages deleted
        """
        # First, get count of messages
        count_response = (
            self.supabase.table(self.table_name)
            .select("id", count="exact")
            .eq("patient_id", patient_id)
            .execute()
        )

        message_count = count_response.count if count_response.count else 0

        # Delete all messages
        if message_count > 0:
            self.supabase.table(self.table_name).delete().eq("patient_id", patient_id).execute()

        return message_count

    def convert_to_deepseek_messages(
        self,
        chat_messages: List[ChatMessage]
    ) -> List[DeepSeekMessage]:
        """
        Convert ChatMessage objects to DeepSeekMessage format.

        Args:
            chat_messages: List of ChatMessage objects

        Returns:
            List of DeepSeekMessage objects
        """
        return [
            DeepSeekMessage(role=msg.role, content=msg.content)
            for msg in chat_messages
            if msg.role in ["user", "assistant"]  # Exclude system messages
        ]

    async def get_conversation_count(self, patient_id: int) -> int:
        """
        Get the total number of messages in a patient's conversation history.

        Args:
            patient_id: Patient ID

        Returns:
            Total message count
        """
        response = (
            self.supabase.table(self.table_name)
            .select("id", count="exact")
            .eq("patient_id", patient_id)
            .execute()
        )

        return response.count if response.count else 0


# Singleton instance
_conversation_service: Optional[ConversationService] = None


def get_conversation_service() -> ConversationService:
    """Get or create the singleton ConversationService instance."""
    global _conversation_service
    if _conversation_service is None:
        _conversation_service = ConversationService()
    return _conversation_service
