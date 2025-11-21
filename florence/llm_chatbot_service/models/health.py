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


class HealthContext(BaseModel):
    """Health context formatted for LLM prompt."""
    raw_monitor_data: str
    raw_activity_logs: str
    raw_daily_logs: str
    patient_thresholds: str
    data_timestamp: str

    def format_for_prompt(self) -> str:
        """Format health context for inclusion in LLM prompt."""
        lines = []
        
        lines.append("=== PATIENT THRESHOLDS ===")
        lines.append(self.patient_thresholds)
        lines.append("")
        
        lines.append("=== MONITOR DATA (Glucose, BP, etc) ===")
        lines.append(self.raw_monitor_data)
        lines.append("")
        
        lines.append("=== ACTIVITY LOGS ===")
        lines.append(self.raw_activity_logs)
        lines.append("")
        
        lines.append("=== DAILY LOGS (Meals) ===")
        lines.append(self.raw_daily_logs)
        lines.append("")

        lines.append(f"Data as of: {self.data_timestamp}")

        return "\n".join(lines)
