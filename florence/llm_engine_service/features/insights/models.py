from typing import Optional, List
from pydantic import BaseModel


class HealthSnapshot(BaseModel):
    glucose_unit: str = "mmol/L"
    average_glucose_7d: Optional[float] = None
    latest_glucose: Optional[float] = None
    hyper_events_7d: int = 0
    hypo_events_7d: int = 0
    time_in_range_7d: float = 0.0
    activity_minutes_today: int = 0
    meals_today: int = 0
    medication_adherence_7d: float = 0.0
    latest_bmi: Optional[float] = None
    active_diseases: List[str] = []
    active_insights: List[str] = []


class InsightRequest(BaseModel):
    health_snapshot: HealthSnapshot


class InsightResponse(BaseModel):
    insight: str
    generated_at: str
