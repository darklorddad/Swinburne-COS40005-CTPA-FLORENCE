from core.llm_factory import LLMFactory
from langchain_core.messages import SystemMessage, HumanMessage
from .models import SimulatedMonth, SimulatorRequest

class SimulatorService:
    def __init__(self):
        # Allow native max output tokens (up to 64k) for massive JSON generation
        self.llm = LLMFactory.create(temperature=0.7).with_structured_output(SimulatedMonth)

    async def generate_patient_data(self, request: SimulatorRequest) -> SimulatedMonth:
        prompt = f"""
        You are a medical data simulator for the FLORENCE diabetes app.
        Generate EXACTLY {request.days} days of highly realistic synthetic diabetic patient data.
        Scenario Persona: {request.scenario}

        Strict Rules:
        1. Ensure clinical correlation (e.g. 'High Carb' scenario must show high glucose_after and high calories).
        2. Use Malaysian food contexts (e.g. Nasi Lemak, Roti Canai, Laksa, Chicken Rice) and names.
        3. All glucose and cholesterol values MUST be in mmol/L (typical range 3.9 - 15.0).
        4. `day_offset` must start at 0 (today) and go exactly up to {request.days - 1}. Generate all {request.days} days.
        5. Ensure exactly 3 meals per day (BREAKFAST, LUNCH, DINNER).
        6. Include activity only if it aligns with the scenario (sedentary = 0 activity).
        7. Generate the `profile` object with realistic baseline demographics, emergency contacts, and AI text matching the scenario.
        
        8. LONG-TERM VITALS (CRITICAL FOR CHARTS):
           - DO NOT generate HbA1c, Cholesterol, or BMI daily. It is clinically impossible.
           - `hba1c_readings`: Generate exactly 2 readings. One at day_offset 0 (today), and one at day_offset 90.
           - `cholesterol_*_readings`: Generate exactly 1 reading at day_offset 0 for all 4 lipid panels.
           - `bmi_readings`: Generate 1 reading every 30 days (e.g. day 0, 30, 60, 90...).
        """
        
        response = await self.llm.ainvoke([
            SystemMessage(content="You generate strictly formatted JSON matching the schema."),
            HumanMessage(content=prompt)
        ])
        return response
