from fastapi import APIRouter, HTTPException
from features.insights.models import InsightRequest, InsightResponse
from features.insights.service import InsightService

router = APIRouter()


@router.post("/generate", response_model=InsightResponse)
async def generate_insight(request: InsightRequest):
    """
    Generate a single AI health insight for the dashboard card.

    Receives a lightweight patient health snapshot and returns one concise,
    personalised insight sentence with a concrete action for today.
    """
    service = InsightService()
    try:
        return await service.generate_insight(request)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate insight: {str(e)}",
        )
