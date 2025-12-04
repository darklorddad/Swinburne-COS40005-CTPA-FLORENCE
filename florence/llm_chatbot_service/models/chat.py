"""
Pydantic models for chat-related data structures.
"""
from datetime import datetime
from typing import Optional, Literal
from pydantic import BaseModel, Field


class ChatMessage(BaseModel):
    """Represents a single chat message."""
    id: Optional[str] = None
    role: Literal["user", "assistant", "system"]
    content: str
    timestamp: datetime = Field(default_factory=datetime.now)
    context: Optional[dict] = None


class ChatMessageRequest(BaseModel):
    """Request model for sending a chat message."""
    message: str = Field(..., min_length=1, max_length=2000)
    include_history: bool = True


class ChatMessageResponse(BaseModel):
    """Response model for chat message endpoint."""
    message_id: str
    role: Literal["assistant"]
    content: str
    timestamp: datetime
    context_used: Optional[dict] = None


class ChatHistoryResponse(BaseModel):
    """Response model for chat history endpoint."""
    messages: list[ChatMessage]
    total_count: int


class ClearHistoryResponse(BaseModel):
    """Response model for clearing chat history."""
    message: str
    cleared_count: int


class LLMMessage(BaseModel):
    """Message format for LLM API."""
    role: Literal["system", "user", "assistant"]
    content: str


class LLMRequest(BaseModel):
    """Request format for LLM API."""
    model: str
    messages: list[LLMMessage]
    temperature: Optional[float] = None
    max_tokens: Optional[int] = None
    stream: bool = False


class LLMChoice(BaseModel):
    """Choice object in LLM response."""
    message: LLMMessage
    finish_reason: str


class LLMUsage(BaseModel):
    """Token usage information from LLM."""
    prompt_tokens: Optional[int] = None
    completion_tokens: Optional[int] = None
    total_tokens: Optional[int] = None


class LLMResponse(BaseModel):
    """Response format from LLM API."""
    choices: list[LLMChoice]
    usage: Optional[LLMUsage] = None
    model: str
