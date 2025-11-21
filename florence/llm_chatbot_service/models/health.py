"""
Pydantic models for health data structures.
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class MonitorData(BaseModel):
    """Monitor data reading (glucose, BP, etc.)."""
    id: int
    patient_id: int
    data_type: str
    value: float
    measured_at: datetime


class ActivityLog(BaseModel):
    """Patient activity log."""
    id: int
    patient_id: int
    activity_description: str
    duration_minutes: int
    performed_at: datetime


class DailyLog(BaseModel):
    """Daily meal and glucose log."""
    id: int
    patient_id: int
    log_date: datetime
    meal_time: str  # BREAKFAST, LUNCH, DINNER
    meal_desc: Optional[str] = None
    glucose_before_meal: Optional[float] = None
    glucose_after_meal: Optional[float] = None
    glucose_before_meal_time: Optional[datetime] = None
    glucose_after_meal_time: Optional[datetime] = None


class HealthSummary(BaseModel):
    """Aggregated health metrics summary."""
    start_date: datetime
    end_date: datetime

    # Glucose metrics
    latest_glucose: Optional[float] = None
    latest_glucose_time: Optional[datetime] = None
    latest_glucose_context: Optional[str] = None
    average_glucose: Optional[float] = None
    glucose_std_dev: Optional[float] = None
    total_glucose_readings: int = 0
    hyper_events: int = 0  # Count of readings > 180 mg/dL
    hypo_events: int = 0   # Count of readings < 70 mg/dL
    time_in_range: float = 0.0  # Percentage 70-180 mg/dL
    estimated_a1c: Optional[float] = None

    # Blood Pressure metrics
    average_systolic: Optional[float] = None
    average_diastolic: Optional[float] = None

    # Activity metrics
    total_activity_minutes: int = 0
    average_daily_activity: float = 0.0

    # Meal metrics
    total_meals: int = 0

    # Other metrics
    latest_bmi: Optional[float] = None
    latest_hba1c: Optional[float] = None


class HealthContext(BaseModel):
    """Health context formatted for LLM prompt."""
    latest_glucose: Optional[float] = None
    latest_glucose_time: Optional[str] = None
    latest_glucose_context: Optional[str] = None
    average_glucose_7d: Optional[float] = None
    time_in_range_7d: float = 0.0
    hyper_events_7d: int = 0
    hypo_events_7d: int = 0
    total_activity_minutes_7d: int = 0
    average_systolic_7d: Optional[float] = None
    average_diastolic_7d: Optional[float] = None
    data_timestamp: str

    def format_for_prompt(self) -> str:
        """Format health context for inclusion in LLM prompt."""
        lines = []

        if self.latest_glucose:
            lines.append(f"Latest Glucose: {self.latest_glucose} mg/dL")
            if self.latest_glucose_time:
                lines.append(f"  Measured: {self.latest_glucose_time}")
            if self.latest_glucose_context:
                lines.append(f"  Context: {self.latest_glucose_context}")

        if self.average_glucose_7d:
            lines.append(f"Average Glucose: {self.average_glucose_7d:.1f} mg/dL")

        lines.append(f"Time in Range (70-180): {self.time_in_range_7d:.1f}%")

        if self.hyper_events_7d > 0:
            lines.append(f"High Glucose Events (>180): {self.hyper_events_7d}")

        if self.hypo_events_7d > 0:
            lines.append(f"Low Glucose Events (<70): {self.hypo_events_7d}")

        if self.average_systolic_7d and self.average_diastolic_7d:
            lines.append(f"Average BP: {self.average_systolic_7d:.0f}/{self.average_diastolic_7d:.0f} mmHg")

        if self.total_activity_minutes_7d > 0:
            lines.append(f"Total Activity: {self.total_activity_minutes_7d} minutes")

        lines.append(f"Data as of: {self.data_timestamp}")

        return "\n".join(lines)
