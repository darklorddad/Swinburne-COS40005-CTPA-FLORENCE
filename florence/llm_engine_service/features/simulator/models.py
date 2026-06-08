from pydantic import BaseModel, Field
from typing import Optional, List

class SimulatedMeal(BaseModel):
    meal_time: str = Field(description="BREAKFAST, LUNCH, or DINNER")
    description: str = Field(description="Name of the food, Malaysian context preferred")
    calories: int
    glucose_before: float = Field(description="Glucose before meal in mmol/L (3.0 - 20.0)")
    glucose_after: float = Field(description="Glucose 2 hours after meal in mmol/L (3.0 - 20.0)")

class SimulatedActivity(BaseModel):
    description: str
    duration_minutes: int
    calories_burned: int

class SimulatedDay(BaseModel):
    day_offset: int = Field(description="0 for today, 1 for yesterday, etc.")
    meals: List[SimulatedMeal]
    activity: Optional[SimulatedActivity] = None
    systolic_bp: int
    diastolic_bp: int

class HistoricalReading(BaseModel):
    day_offset: int = Field(description="Days ago (e.g., 0 for today, 90 for 90 days ago)")
    value: float

class SimulatedMonth(BaseModel):
    days: List[SimulatedDay]
    hba1c_readings: List[HistoricalReading] = Field(description="HbA1c % over time. Generate exactly 2 readings spaced 90 days apart (e.g. day 0 and day 90).")
    cholesterol_total_readings: List[HistoricalReading] = Field(description="Total cholesterol over time. Generate exactly 1 reading at day 0.")
    cholesterol_ldl_readings: List[HistoricalReading] = Field(description="LDL over time. Generate exactly 1 reading at day 0.")
    cholesterol_hdl_readings: List[HistoricalReading] = Field(description="HDL over time. Generate exactly 1 reading at day 0.")
    cholesterol_triglycerides_readings: List[HistoricalReading] = Field(description="Triglycerides over time. Generate exactly 1 reading at day 0.")
    bmi_readings: List[HistoricalReading] = Field(description="BMI over time. Generate 1 reading every 30 days (e.g. day 0, 30, 60...).")

class SimulatorRequest(BaseModel):
    scenario: str
    days: int = 30
