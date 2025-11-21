"""
Chat API endpoints for the Florence Chatbot Service.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional
import logging

from utils.auth import get_current_patient
from services import (
    get_health_data_service,
    get_deepseek_service,
    get_conversation_service,
)
from models.chat import (
    ChatMessageRequest,
    ChatMessageResponse,
    ChatHistoryResponse,
    ClearHistoryResponse,
    DeepSeekMessage,
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create router
router = APIRouter(prefix="/chat", tags=["chat"])


@router.post("/message", response_model=ChatMessageResponse)
async def send_message(
    request: ChatMessageRequest,
    patient: dict = Depends(get_current_patient)
):
    """
    Send a message to the chatbot and get an AI-powered response.
    """
    patient_id = patient["patient_id"]
    token = patient["token"]

    try:
        # Get service instances
        health_service = get_health_data_service()
        deepseek_service = get_deepseek_service()
        conversation_service = get_conversation_service()

        # Save user message
        user_message = await conversation_service.save_message(
            token=token,
            role="user",
            content=request.message
        )

        logger.info(f"Patient {patient_id} sent message: {request.message[:50]}...")

        # Get health context
        health_context = await health_service.get_health_context(token)
        health_context_formatted = health_context.format_for_prompt()

        # Build system prompt with health context
        system_prompt = deepseek_service.build_system_prompt(health_context_formatted)

        # Prepare messages for LLM
        messages = [DeepSeekMessage(role="system", content=system_prompt)]

        # Add conversation history if requested
        if request.include_history:
            # Fetch all history (using a large limit)
            history = await conversation_service.get_conversation_history(token, limit=10000)
            # Convert to DeepSeek format (excludes system messages)
            history_messages = conversation_service.convert_to_deepseek_messages(history)
            messages.extend(history_messages)

        # Add current user message
        messages.append(DeepSeekMessage(role="user", content=request.message))

        # Call DeepSeek API
        assistant_content = await deepseek_service.chat_completion(messages)
        logger.info(f"DeepSeek responded to patient {patient_id}")

        # Save assistant response with health context
        assistant_message = await conversation_service.save_message(
            token=token,
            role="assistant",
            content=assistant_content,
            context=health_context.model_dump()
        )

        return ChatMessageResponse(
            message_id=assistant_message.id,
            role="assistant",
            content=assistant_content,
            timestamp=assistant_message.timestamp,
            context_used=health_context.model_dump(),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing chat message for patient {patient_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error processing message: {str(e)}"
        )


@router.get("/history", response_model=ChatHistoryResponse)
async def get_chat_history(
    limit: Optional[int] = 50,
    patient: dict = Depends(get_current_patient)
):
    """
    Retrieve conversation history for the authenticated patient.
    """
    patient_id = patient["patient_id"]
    token = patient["token"]

    # Validate limit
    if limit <= 0 or limit > 100:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Limit must be between 1 and 100"
        )

    try:
        conversation_service = get_conversation_service()

        # Get conversation history
        messages = await conversation_service.get_conversation_history(
            token=token,
            limit=limit
        )

        # Get total count
        total_count = await conversation_service.get_conversation_count(token)

        logger.info(f"Retrieved {len(messages)} messages for patient {patient_id}")

        return ChatHistoryResponse(
            messages=messages,
            total_count=total_count
        )

    except Exception as e:
        logger.error(f"Error retrieving chat history for patient {patient_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving chat history: {str(e)}"
        )


@router.delete("/history", response_model=ClearHistoryResponse)
async def clear_chat_history(patient: dict = Depends(get_current_patient)):
    """
    Clear all conversation history for the authenticated patient.
    """
    patient_id = patient["patient_id"]
    token = patient["token"]

    try:
        conversation_service = get_conversation_service()

        # Clear conversation history
        cleared_count = await conversation_service.clear_conversation_history(token)

        logger.info(f"Cleared history for patient {patient_id}")

        return ClearHistoryResponse(
            message="Chat history cleared successfully",
            cleared_count=cleared_count
        )

    except Exception as e:
        logger.error(f"Error clearing chat history for patient {patient_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error clearing chat history: {str(e)}"
        )
