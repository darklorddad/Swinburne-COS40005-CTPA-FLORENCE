from pydantic import BaseModel
from typing import Optional, List, Dict, Any


class HealthSummaryRequest(BaseModel):
    # Core aggregates
    glucose_unit: str = "mmol/L"    # User's preferred unit (mmol/L or mg/dL)
    cholesterol_unit: str = "mmol/L" # User's preferred unit (mmol/L or mg/dL)
    average_glucose: float          # 7-day average in user's preferred unit
    glucose_std_dev: float          # variability measure in user's preferred unit
    hyper_events: int               # readings > 180 mg/dL in period
    hypo_events: int                # readings < 70 mg/dL in period
    time_in_range: float            # % of readings between 70–180 mg/dL
    estimated_a1c: float            # estimated HbA1c %
    total_meals: int                # meals logged in period
    average_calories: float         # avg kcal/meal (carbs not stored in DB)
    total_activity_minutes: int     # total activity minutes in period
    medication_adherence: float     # 0.0–1.0 today's adherence from schedule API

    # Extended vitals (optional — present when patient has logged them)
    latest_bmi: Optional[float] = None
    latest_systolic: Optional[float] = None
    latest_diastolic: Optional[float] = None
    latest_cholesterol: Optional[float] = None      # total cholesterol
    latest_hdl: Optional[float] = None              # HDL cholesterol
    latest_ldl: Optional[float] = None              # LDL cholesterol
    latest_triglycerides: Optional[float] = None    # triglycerides
    latest_hba1c: Optional[float] = None            # lab-measured HbA1c %

    # Disease & medication context (live from Supabase — changes as patient updates their cabinet)
    active_diseases: Optional[List[str]] = None     # active condition names e.g. ["Type 2 Diabetes"]
    current_medications: Optional[List[Dict[str, Any]]] = None  # [{name, amount, timing, type}]

    # Individual recent readings for pattern detection
    recent_glucose_readings: Optional[List[Dict[str, Any]]] = None  # [{value, timestamp}]
    recent_meals: Optional[List[Dict[str, Any]]] = None  # [{type, description, calories, glucose_before, glucose_after, timestamp}]
    recent_activities: Optional[List[Dict[str, Any]]] = None  # [{type, duration_minutes, calories_burned, timestamp}]


class RecommendationRequest(BaseModel):
    health_summary: HealthSummaryRequest
    analysis_period_days: int = 7
    previous_recommendation_titles: Optional[List[str]] = None


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


class UnifiedAnalysisResponse(BaseModel):
    risk_level: str
    risk_rationale: str
    daily_insight: str
    recommendations: List[HealthRecommendationItem]
    generated_at: str
    model_used: str
