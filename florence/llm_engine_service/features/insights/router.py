from fastapi import APIRouter, HTTPException, Depends
from features.insights.models import InsightRequest, InsightResponse
from features.insights.service import InsightService
from core.ds_client import get_auth_token

router = APIRouter()


@router.post("/generate", response_model=InsightResponse)
async def generate_insight(
    request: InsightRequest,
    token: str = Depends(get_auth_token),
):
    """
    Generate a single AI health insight for the dashboard card.

    Receives a lightweight patient health snapshot and returns one concise,
    personalised insight sentence with a concrete action for today.
    """
    service = InsightService()
    try:
        return await service.generate_insight(request, token)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate insight: {str(e)}",
        )
