import base64
from langchain_core.messages import HumanMessage
from core.llm_factory import LLMFactory
from features.biometrics.models import ParsedLipidPanel, ParsedHbA1c

class BiometricsService:
    async def parse_lab_report(self, file_bytes: bytes, mime_type: str, report_type: str):
        # Encode the file for the vision model
        encoded_image = base64.b64encode(file_bytes).decode("utf-8")
        
        # Route the logic based on what the frontend requested
        if report_type == "lipid_panel":
            schema = ParsedLipidPanel
            task_instruction = "Extract the lipid panel (cholesterol) values from this lab report. Capture the correct unit (mg/dL or mmol/L)."
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
        
        return await llm.ainvoke([message])
