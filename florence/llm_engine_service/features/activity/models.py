from pydantic import BaseModel
from typing import Optional

class CalorieEstimationRequest(BaseModel):
    active_duration_minutes: int
    activity_description: str
    weight_kg: Optional[float] = 70.0
    height_cm: Optional[float] = 170.0
    age: Optional[int] = 30
    gender: Optional[str] = "unknown"

class CalorieEstimationResponse(BaseModel):
    estimated_calories: int
    explanation: str
