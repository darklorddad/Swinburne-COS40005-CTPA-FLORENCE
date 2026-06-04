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

class SimulatedMonth(BaseModel):
    days: List[SimulatedDay]
    hba1c: float = Field(description="HbA1c percentage (e.g. 6.5)")
    cholesterol_total: float = Field(description="Total cholesterol in mmol/L")
    cholesterol_ldl: float = Field(description="LDL in mmol/L")
    cholesterol_hdl: float = Field(description="HDL in mmol/L")
    cholesterol_triglycerides: float = Field(description="Triglycerides in mmol/L")
    bmi: float

class SimulatorRequest(BaseModel):
    scenario: str
    days: int = 30
