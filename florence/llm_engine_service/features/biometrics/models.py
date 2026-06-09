from pydantic import BaseModel, Field
from typing import Optional

class ExtractedBiometric(BaseModel):
    value: Optional[float] = Field(description="The numeric value found on the report")
    unit_on_paper: Optional[str] = Field(description="The unit exactly as printed (e.g., mg/dL or mmol/L)")

class ParsedLipidPanel(BaseModel):
    total_cholesterol: ExtractedBiometric
    ldl: ExtractedBiometric
    hdl: ExtractedBiometric
    triglycerides: ExtractedBiometric

class ParsedHbA1c(BaseModel):
    hba1c_percentage: Optional[float] = Field(description="HbA1c percentage value")
    estimated_average_glucose: Optional[float] = Field(description="eAG (Estimated Average Glucose) if present")
    units: Optional[str] = Field(description="Units for eAG, usually mg/dL or mmol/L")
