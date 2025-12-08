from fastapi import APIRouter, HTTPException
from .models import FoodAnalysisRequest, FoodAnalysisResponse
from .service import NutritionService

router = APIRouter()

@router.post("/analyze", response_model=FoodAnalysisResponse)
async def analyze_food(request: FoodAnalysisRequest):
    if not request.image_url:
        raise HTTPException(status_code=400, detail="Image URL is required")
        
    service = NutritionService()
    return await service.analyze_food_image(request.image_url)
