import json
import re
import httpx
from pydantic import BaseModel
from langchain_core.messages import HumanMessage, SystemMessage
from core.llm_factory import LLMFactory
from config import settings

class RiskResponse(BaseModel):
    risk_level: str
    risk_rationale: str

_SYSTEM_PROMPT = """You are a clinical decision-support AI. 
Analyze the provided patient health summary and their PERSONALIZED clinical thresholds.
Assign a clinical risk level for clinician prioritization.

## MEDICAL GUARDRAILS
You are a guidance tool, not a doctor. You MUST NOT diagnose conditions or prescribe treatments. You are assessing risk levels purely based on data thresholds for clinician triage.

## Output Rules
1. risk_level MUST be exactly "LOW", "MEDIUM", or "HIGH".
2. risk_rationale must be a concise, professional, 1-2 sentence clinical summary written FOR THE CLINICIAN. MUST use third-person objective language (e.g., "The patient's glucose...", "Their adherence..."). NEVER use "you" or "your".
3. Evaluate the data strictly against the patient's personalized thresholds provided below, NOT general medical defaults.
4. Do NOT use alarming language. Be objective and factual.
"""

class RiskAssessmentService:
    def __init__(self):
        # Low temperature for consistent, factual clinical output
        self.llm = LLMFactory.create(temperature=0.2)

    async def assess_patient_risk(self, token: str) -> dict:
        headers = {"Authorization": f"Bearer {token}"}
        
        async with httpx.AsyncClient() as client:
            # 1. Fetch Profile
            profile_res = await client.get(f"{settings.DATA_SERVICE_URL}/patients/me", headers=headers, timeout=5.0)
            profile = profile_res.json() if profile_res.status_code == 200 else {}

            # 2. Fetch Data & Personalized Thresholds (Data Service handles Unit Conversion automatically)
            monitor_res = await client.get(f"{settings.DATA_SERVICE_URL}/patients/me/monitor-data", headers=headers, timeout=10.0)
            monitor_data = monitor_res.json() if monitor_res.status_code == 200 else []
            
            daily_res = await client.get(f"{settings.DATA_SERVICE_URL}/patients/me/daily-logs", headers=headers, timeout=10.0)
            daily_data = daily_res.json() if daily_res.status_code == 200 else []

            thresh_res = await client.get(f"{settings.DATA_SERVICE_URL}/patients/me/thresholds", headers=headers, timeout=5.0)
            thresholds = thresh_res.json() if thresh_res.status_code == 200 else []

        # 3. Build Context for LLM
        # Grab the last 10 readings regardless of type (BP, BMI, Glucose, etc.)
        recent_readings = []
        for d in monitor_data[:10]:
            recent_readings.append(f"{d.get('data_type')}: {d.get('value')}")
            
        # Format thresholds for the prompt
        thresh_text = "No specific thresholds set."
        if thresholds:
            thresh_text = "\n".join([f"- {t['data_type']}: Target {t['min_value']} to {t['max_value']}" for t in thresholds])

        summary = f"""
Recent monitor readings (latest first): {', '.join(recent_readings) if recent_readings else 'None'}
Recent meal logs count: {len(daily_data)}

Patient's Personalized Thresholds (in their preferred units):
{thresh_text}
"""

        # 4. Prompt LLM
        try:
            llm_structured = self.llm.with_structured_output(RiskResponse)
            response_data = await llm_structured.ainvoke([
                SystemMessage(content=_SYSTEM_PROMPT),
                HumanMessage(content=summary)
            ])
            
            # 5. Update the patient profile via Data Service
            async with httpx.AsyncClient() as client:
                await client.patch(
                    f"{settings.DATA_SERVICE_URL}/patients/me/risk",
                    headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
                    json={
                        "risk_level": response_data.risk_level.upper(), 
                        "risk_rationale": response_data.risk_rationale
                    },
                    timeout=10.0
                )
            
            return {"risk_level": response_data.risk_level.upper(), "risk_rationale": response_data.risk_rationale}
        except Exception as e:
            print(f"[RiskAssessmentService] LLM/DB Error: {e}")
            raise
