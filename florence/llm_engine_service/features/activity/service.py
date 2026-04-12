from core.llm_factory import LLMFactory
from langchain_core.prompts import ChatPromptTemplate
from .models import CalorieEstimationRequest, CalorieEstimationResponse
import json

class ActivityService:
    def __init__(self):
        self.llm = LLMFactory.create(temperature=0.1)

    async def estimate_calories(self, request: CalorieEstimationRequest) -> CalorieEstimationResponse:
        prompt = ChatPromptTemplate.from_messages([
            ("system", "You are an expert sports physiologist and metabolic rate calculator. Estimate the calories burned based on the provided activity description, duration, and patient biometrics using METs (Metabolic Equivalent of Task). Return ONLY a valid JSON object with two keys: 'estimated_calories' (integer) and 'explanation' (short string explaining the MET value used)."),
            ("user", "Activity: {activity}\nDuration: {duration} mins\nWeight: {weight} kg\nHeight: {height} cm\nAge: {age}\nGender: {gender}")
        ])
        
        chain = prompt | self.llm
        response = await chain.ainvoke({
            "activity": request.activity_description,
            "duration": request.active_duration_minutes,
            "weight": request.weight_kg,
            "height": request.height_cm,
            "age": request.age,
            "gender": request.gender
        })
        
        try:
            content = response.content.strip()
            if content.startswith("```json"):
                content = content[7:-3].strip()
            elif content.startswith("```"):
                content = content[3:-3].strip()
            data = json.loads(content)
            return CalorieEstimationResponse(
                estimated_calories=int(data.get("estimated_calories", 0)),
                explanation=data.get("explanation", "")
            )
        except Exception as e:
            # Fallback
            return CalorieEstimationResponse(
                estimated_calories=request.active_duration_minutes * 5,
                explanation="Fallback calculation due to parsing error."
            )
