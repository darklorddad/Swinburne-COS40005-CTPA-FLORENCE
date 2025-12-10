import json
import base64
from langchain_core.messages import HumanMessage, SystemMessage
from core.llm_factory import LLMFactory
from features.nutrition.models import FoodAnalysisResponse

class NutritionService:
    def __init__(self):
        self.llm = LLMFactory.create()

    async def analyze_food_image(self, image_bytes: bytes) -> FoodAnalysisResponse:
        # Encode bytes to base64 string
        base64_image = base64.b64encode(image_bytes).decode('utf-8')
        
        system_prompt = """You are a nutrition expert AI. 
        Analyze the food image provided.
        Return ONLY a raw JSON object. Do not use markdown code blocks.
        
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

        # Send as Data URI
        message = HumanMessage(
            content=[
                {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}},
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
