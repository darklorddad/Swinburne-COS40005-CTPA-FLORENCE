import json
import re
import httpx
from langchain_core.messages import HumanMessage, SystemMessage
from core.llm_factory import LLMFactory
from config import settings

_SYSTEM_PROMPT = """You are a clinical decision-support AI. 
Analyze the provided patient health summary and assign a clinical risk level for clinician prioritization.

## Output Rules
1. Return ONLY raw JSON. No markdown, no backticks.
2. risk_level MUST be exactly "LOW", "MEDIUM", or "HIGH".
3. risk_rationale must be a concise, professional, 1-2 sentence clinical summary for the clinician.
4. Do NOT use alarming language. Be objective and factual.

## Required JSON Schema
{
  "risk_level": "LOW" | "MEDIUM" | "HIGH",
  "risk_rationale": "string"
}
"""

class RiskAssessmentService:
    def __init__(self):
        self.llm = LLMFactory.create(temperature=0.2)

    async def assess_patient_risk(self, token: str) -> dict:
        try:
            # 1. Fetch recent data from Data Service using the patient's token (Enforces RLS)
            headers = {"Authorization": f"Bearer {token}"}
            async with httpx.AsyncClient() as client:
                monitor_res = await client.get(f"{settings.DATA_SERVICE_URL}/patients/me/monitor-data", headers=headers, timeout=10.0)
                monitor_data = monitor_res.json() if monitor_res.status_code == 200 else []
                
                daily_res = await client.get(f"{settings.DATA_SERVICE_URL}/patients/me/daily-logs", headers=headers, timeout=10.0)
                daily_data = daily_res.json() if daily_res.status_code == 200 else []

            # 2. Build lightweight summary for the LLM
            glucose_readings = [d for d in monitor_data if d.get('data_type') == 'GLUCOSE'][-5:] # Last 5
            summary = f"Recent monitor readings: {len(monitor_data)}. Recent meal logs: {len(daily_data)}. Recent glucose: {glucose_readings}"

            # 3. Prompt LLM
            response = await self.llm.ainvoke([
                SystemMessage(content=_SYSTEM_PROMPT),
                HumanMessage(content=summary)
            ])
            
            content = re.sub(r'```json\s*|\s*```', '', response.content).strip()
            data = json.loads(content)
            
            # 4. Update the patient profile via Data Service
            async with httpx.AsyncClient() as client:
                await client.patch(
                    f"{settings.DATA_SERVICE_URL}/patients/me/risk",
                    headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
                    json={"risk_level": data['risk_level'], "risk_rationale": data['risk_rationale']},
                    timeout=10.0
                )
            
            return data
        except Exception as e:
            print(f"[RiskAssessmentService] Error: {e}")
            raise
