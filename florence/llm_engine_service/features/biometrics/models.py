from pydantic import BaseModel, Field
from typing import Optional

class ParsedLipidPanel(BaseModel):
    total_cholesterol: Optional[float] = Field(description="Total cholesterol value")
    hdl: Optional[float] = Field(description="HDL value")
    ldl: Optional[float] = Field(description="LDL value")
    triglycerides: Optional[float] = Field(description="Triglycerides value")
    units: str = Field(description="Unit of measurement, either 'mg/dL' or 'mmol/L'")

class ParsedHbA1c(BaseModel):
    hba1c_percentage: Optional[float] = Field(description="HbA1c percentage value")
    estimated_average_glucose: Optional[float] = Field(description="eAG (Estimated Average Glucose) if present")
    units: Optional[str] = Field(description="Units for eAG, usually mg/dL or mmol/L")
