from core.llm_factory import LLMFactory
from langchain_core.messages import SystemMessage, HumanMessage
from .models import SimulatedMonth, SimulatorRequest

class SimulatorService:
    def __init__(self):
        # Increased token limit as we are generating a massive 30-day JSON block
        self.llm = LLMFactory.create(temperature=0.7, max_tokens=16000).with_structured_output(SimulatedMonth)

    async def generate_patient_data(self, request: SimulatorRequest) -> SimulatedMonth:
        prompt = f"""
        You are a medical data simulator for the FLORENCE diabetes app.
        Generate EXACTLY {request.days} days of highly realistic synthetic diabetic patient data.
        
        Scenario Persona: {request.scenario}
        
        Strict Rules:
        1. Ensure clinical correlation (e.g. 'High Carb' scenario must show high glucose_after and high calories).
        2. Use Malaysian food contexts (e.g. Nasi Lemak, Roti Canai, Laksa, Chicken Rice) where appropriate.
        3. All glucose values MUST be in mmol/L (typical range 3.9 - 15.0).
        4. `day_offset` must start at 0 (today) and go exactly up to {request.days - 1}. Generate all {request.days} days.
        5. Ensure exactly 3 meals per day (BREAKFAST, LUNCH, DINNER).
        6. Include activity only if it aligns with the scenario (sedentary = 0 activity).
        """
        
        response = await self.llm.ainvoke([
            SystemMessage(content="You generate strictly formatted JSON matching the schema."),
            HumanMessage(content=prompt)
        ])
        return response
