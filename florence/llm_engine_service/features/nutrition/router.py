from fastapi import APIRouter, HTTPException, UploadFile, File
from features.nutrition.models import FoodAnalysisResponse
from features.nutrition.service import NutritionService

router = APIRouter()

@router.post("/analyze", response_model=FoodAnalysisResponse)
async def analyze_food(file: UploadFile = File(...)):
    if not file:
        raise HTTPException(status_code=400, detail="Image file is required")
    
    # Read bytes from the uploaded file
    image_bytes = await file.read()
    
    service = NutritionService()
    return await service.analyze_food_image(image_bytes)
