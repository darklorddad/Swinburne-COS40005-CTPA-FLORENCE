import json
from langchain_core.messages import HumanMessage, SystemMessage
from ...core.llm_factory import LLMFactory
from .models import FoodAnalysisResponse

class NutritionService:
    def __init__(self):
        # specific low temp for factual analysis
        self.llm = LLMFactory.create(temperature=0.1)

    async def analyze_food_image(self, image_url: str) -> FoodAnalysisResponse:
        system_prompt = """You are a nutrition expert AI. 
        Analyze the food image provided.
        Return ONLY a raw JSON object (no markdown, no backticks).
        
        Schema:
        {
            "calories": integer (estimated total),
            "description": string (concise meal name),
            "macronutrients": {
                "protein": string (e.g. "20g"),
                "carbs": string,
                "fat": string
            }
        }
        
        If not food, return {"calories": 0, "description": "Not food detected", "macronutrients": null}
        """

        message = HumanMessage(
            content=[
                {"type": "image_url", "image_url": {"url": image_url}},
            ]
        )

        try:
            response = await self.llm.ainvoke([
                SystemMessage(content=system_prompt),
                message
            ])
            
            # Clean possible markdown formatting from LLM
            content = response.content.replace('```json', '').replace('```', '').strip()
            data = json.loads(content)
            
            return FoodAnalysisResponse(**data)
            
        except Exception as e:
            print(f"Analysis Error: {e}")
            return FoodAnalysisResponse(
                calories=None,
                description="Analysis failed. Please try again."
            )
