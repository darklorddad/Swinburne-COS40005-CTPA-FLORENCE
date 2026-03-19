from pydantic import BaseModel
from typing import Optional, List


class HealthSummaryRequest(BaseModel):
    average_glucose: float          # mg/dL, 7-day average
    glucose_std_dev: float          # mg/dL, variability measure
    hyper_events: int               # readings > 180 mg/dL in period
    hypo_events: int                # readings < 70 mg/dL in period
    time_in_range: float            # % of readings between 70–180 mg/dL
    estimated_a1c: float            # estimated HbA1c %
    total_meals: int                # meals logged in period
    average_carbs: float            # g/meal average
    total_activity_minutes: int     # total activity minutes in period
    medication_adherence: float     # 0.0–1.0 (proportion of doses taken)
    average_sleep_hours: int        # average hours per night


class RecommendationRequest(BaseModel):
    health_summary: HealthSummaryRequest
    analysis_period_days: int = 7


class TriggeringDataPoint(BaseModel):
    type: str           # e.g. "average_glucose", "time_in_range"
    description: str    # human-readable label
    value: str          # actual value with units, e.g. "195 mg/dL"
    timestamp: str      # ISO8601


class RecommendationExplanation(BaseModel):
    rationale: str
    triggering_data: List[TriggeringDataPoint]
    evidence_links: List[str] = []
    expected_impact: str


class HealthRecommendationItem(BaseModel):
    id: str
    category: str       # meal | activity | sleep | medication | lifestyle | timing
    title: str
    description: str
    priority: str       # urgent | high | medium | low
    status: str = "active"
    generated_at: str   # ISO8601
    expires_at: str     # ISO8601, generated_at + 7 days
    action_items: List[str]
    explanation: Optional[RecommendationExplanation] = None


class RecommendationResponse(BaseModel):
    recommendations: List[HealthRecommendationItem]
    generated_at: str
    model_used: str
    analysis_period_days: int
