from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional, Dict, Any, List
from datetime import datetime
from client import supabase
from routers.patients import get_current_patient_profile

router = APIRouter(
    prefix="/chat",
    tags=["Chat History"]
)

class ChatMessageCreate(BaseModel):
    role: str
    content: str
    context: Optional[Dict[str, Any]] = None
    timestamp: Optional[datetime] = None

@router.get("/history")
async def get_history(
    limit: int = 50, 
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """Retrieves chat history for the authenticated patient."""
    try:
        response = (
            supabase.table('patient_chat_history')
            .select("*")
            .eq("patient_id", patient_profile['id'])
            .order("timestamp", desc=False)
            .limit(limit)
            .execute()
        )
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve chat history: {str(e)}")

@router.post("/history")
async def save_message(
    message: ChatMessageCreate, 
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """Saves a chat message for the authenticated patient."""
    try:
        data = message.model_dump(mode='json', exclude_unset=True)
        data['patient_id'] = patient_profile['id']
        
        # If timestamp is not provided, let DB handle it or set it now
        if 'timestamp' not in data or data['timestamp'] is None:
            data['timestamp'] = datetime.now().isoformat()

        response = supabase.table('patient_chat_history').insert(data).execute()
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save message: {str(e)}")

@router.delete("/history")
async def clear_history(
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """Clears all chat history for the authenticated patient."""
    try:
        response = (
            supabase.table('patient_chat_history')
            .delete()
            .eq("patient_id", patient_profile['id'])
            .execute()
        )
        return {"message": "History cleared", "data": response.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to clear history: {str(e)}")
