from fastapi import APIRouter, Depends
from .models import CalorieEstimationRequest, CalorieEstimationResponse
from .service import ActivityService

router = APIRouter()

def get_activity_service():
    return ActivityService()

@router.post("/estimate-calories", response_model=CalorieEstimationResponse)
async def estimate_calories(
    request: CalorieEstimationRequest,
    service: ActivityService = Depends(get_activity_service)
):
    return await service.estimate_calories(request)
