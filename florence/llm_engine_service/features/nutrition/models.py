from pydantic import BaseModel
from typing import Optional, Dict

class FoodAnalysisResponse(BaseModel):
    calories: Optional[int]
    description: str
    macronutrients: Optional[Dict[str, str]] = None
