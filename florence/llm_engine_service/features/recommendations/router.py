from fastapi import APIRouter, HTTPException, Depends
from features.recommendations.models import RecommendationRequest, RecommendationResponse
from features.recommendations.service import RecommendationService
from core.ds_client import get_auth_token

router = APIRouter()


@router.post("/generate", response_model=RecommendationResponse)
async def generate_recommendations(
    request: RecommendationRequest,
    token: str = Depends(get_auth_token),
):
    """
    Generate LLM-powered health recommendations based on a patient's health summary.

    Analyses the provided health metrics and returns 2–6 prioritised recommendations
    across meal, activity, sleep, medication, lifestyle, and timing categories.
    Each recommendation includes actionable steps and a clinical rationale.
    """
    service = RecommendationService()
    try:
        return await service.generate_recommendations(request, token)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate recommendations: {str(e)}",
        )
