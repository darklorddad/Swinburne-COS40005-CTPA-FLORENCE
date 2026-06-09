import base64
from typing import Optional
from langchain_core.messages import HumanMessage
from core.llm_factory import LLMFactory
from features.biometrics.models import ParsedLipidPanel, ParsedHbA1c

class BiometricsService:
    def _standardize_lipid_value(self, extracted, target_unit: str, is_triglyceride: bool = False) -> Optional[float]:
        if not extracted or extracted.value is None:
            return None
            
        paper_unit = (extracted.unit_on_paper or "").lower()
        app_unit = target_unit.lower()
        
        if paper_unit == app_unit or not paper_unit:
            return round(extracted.value, 2)
            
        # Conversion Factors: Triglycerides (88.57), Others (38.67)
        factor = 88.57 if is_triglyceride else 38.67

        if "mg/dl" in paper_unit and "mmol/l" in app_unit:
            return round(extracted.value / factor, 2)
        if "mmol/l" in paper_unit and "mg/dl" in app_unit:
            return round(extracted.value * factor, 2)
            
        return round(extracted.value, 2)

    async def parse_lab_report(self, file_bytes: bytes, mime_type: str, report_type: str, target_unit: str = "mmol/L"):
        # Encode the file for the vision model
        encoded_image = base64.b64encode(file_bytes).decode("utf-8")
        
        # Route the logic based on what the frontend requested
        if report_type == "lipid_panel":
            schema = ParsedLipidPanel
            task_instruction = (
                "Extract the exact numbers and their corresponding units for Total Cholesterol, LDL, HDL, and Triglycerides "
                "exactly as they appear on this lab report. Do not convert or calculate anything. "
                "Return null for any missing values."
            )
        elif report_type == "hba1c":
            schema = ParsedHbA1c
            task_instruction = "Extract the HbA1c percentage and any estimated average glucose (eAG) from this lab report."
        else:
            raise ValueError(f"Unsupported report type: {report_type}")

        # Use your LLMFactory with temperature 0 for strict extraction
        llm = LLMFactory.create(temperature=0.0).with_structured_output(schema)

        message = HumanMessage(
            content=[
                {"type": "text", "text": f"{task_instruction} If a value is missing, leave it null. Do not guess or estimate."},
                {
                    "type": "image_url",
                    "image_url": {"url": f"data:{mime_type};base64,{encoded_image}"},
                },
            ]
        )
        
        result = await llm.ainvoke([message])

        # After receiving result from LLM, standardize the values if it's a lipid panel
        if report_type == "lipid_panel":
            return {
                "total_cholesterol": self._standardize_lipid_value(result.total_cholesterol, target_unit),
                "ldl": self._standardize_lipid_value(result.ldl, target_unit),
                "hdl": self._standardize_lipid_value(result.hdl, target_unit),
                "triglycerides": self._standardize_lipid_value(result.triglycerides, target_unit, is_triglyceride=True)
            }
            
        return result
