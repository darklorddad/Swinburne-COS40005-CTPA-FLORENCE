from pydantic import BaseModel
from typing import Optional

class FoodAnalysisRequest(BaseModel):
    image_url: str

class FoodAnalysisResponse(BaseModel):
    calories: Optional[int]
    description: str
    macronutrients: Optional[dict] = None
