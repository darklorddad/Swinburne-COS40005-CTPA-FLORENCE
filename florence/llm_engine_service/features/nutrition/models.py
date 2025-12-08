from pydantic import BaseModel
from typing import Optional, Dict

class FoodAnalysisRequest(BaseModel):
    image_url: str

class FoodAnalysisResponse(BaseModel):
    calories: Optional[int]
    description: str
    macronutrients: Optional[Dict[str, str]] = None
