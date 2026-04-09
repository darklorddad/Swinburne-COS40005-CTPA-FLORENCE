import json
import re
from datetime import datetime, timezone
from langchain_core.messages import HumanMessage, SystemMessage
from config import settings as global_settings
from core.llm_factory import LLMFactory
from features.recommendations.rec_config import recommendation_settings
from features.recommendations.models import (
    RecommendationRequest,
    RecommendationResponse,
    HealthRecommendationItem,
)

_SYSTEM_PROMPT = """You are a clinical decision-support AI for the FLORENCE Digital Health Platform.
You will receive a patient's health summary. Generate 2–3 concise, evidence-based health recommendations.

## Clinical Targets
- Glucose: 70–180 mg/dL (TIR ≥70%)
- HbA1c: <7.0%
- Activity: ≥150 min/week
- Adherence: ≥80%
- Sleep: 7–9 hours

## Output Rules
1. Return ONLY raw JSON. No markdown, no backticks, no conversational text.
2. Generate exactly 2-3 recommendations. Sort by urgency.
3. Never recommend dose changes.
4. Each recommendation needs 2 specific action_items.
5. Keep descriptions and rationales under 150 characters each.
6. Set expires_at to 7 days after generated_at.
7. ID format: rec_<category>_<timestamp_ms>.

## Required JSON Schema
{
  "recommendations": [
    {
      "id": string,
      "category": "meal" | "activity" | "sleep" | "medication" | "lifestyle" | "timing",
      "title": string,
      "description": string,
      "priority": "urgent" | "high" | "medium" | "low",
      "status": "active",
      "generated_at": string,
      "expires_at": string,
      "action_items": [string],
      "explanation": {
        "rationale": string,
        "triggering_data": [
          {
            "type": string,
            "description": string,
            "value": string,
            "timestamp": string
          }
        ],
        "evidence_links": [],
        "expected_impact": string
      }
    }
  ],
  "generated_at": string,
  "model_used": string,
  "analysis_period_days": integer
}"""


class RecommendationService:
    def __init__(self):
        # temperature=0.3: grounded clinical outputs with slight variation across calls
        # model: isolated per-feature config — does not affect chatbot or nutrition
        model = (
            recommendation_settings.LLM_MODEL
            or global_settings.LLM_MODEL
        )
        self.llm = LLMFactory.create(
            temperature=0.3,
            model=model,
            max_tokens=recommendation_settings.LLM_MAX_TOKENS,
        )

    async def generate_recommendations(
        self, request: RecommendationRequest
    ) -> RecommendationResponse:
        now = datetime.now(timezone.utc)
        now_iso = now.isoformat()
        s = request.health_summary

        human_content = f"""Please generate health recommendations for a patient with the following {request.analysis_period_days}-day health summary.

Patient Health Summary ({request.analysis_period_days}-day period):
- Average Blood Glucose: {s.average_glucose:.1f} mg/dL
- Glucose Variability (Std Dev): {s.glucose_std_dev:.1f} mg/dL
- Hyperglycaemia Events (>180 mg/dL): {s.hyper_events}
- Hypoglycaemia Events (<70 mg/dL): {s.hypo_events}
- Time in Target Range (70–180 mg/dL): {s.time_in_range:.1f}%
- Estimated HbA1c: {s.estimated_a1c:.1f}%
- Total Meals Logged: {s.total_meals}
- Average Carbohydrates per Meal: {s.average_carbs:.1f}g
- Total Activity Minutes: {s.total_activity_minutes} minutes
- Medication Adherence: {s.medication_adherence * 100:.0f}%
- Average Sleep: {s.average_sleep_hours} hours/night

Current timestamp for generated_at: {now_iso}"""

        try:
            response = await self.llm.ainvoke([
                SystemMessage(content=_SYSTEM_PROMPT),
                HumanMessage(content=human_content),
            ])

            content = response.content

            # Remove <think> blocks (often returned by reasoning models like DeepSeek R1)
            content = re.sub(r'<think>.*?</think>', '', content, flags=re.DOTALL)

            # Find the JSON block to strip out any conversational fluff
            start_idx = content.find('{')
            end_idx = content.rfind('}')
            if start_idx != -1 and end_idx != -1:
                content = content[start_idx:end_idx + 1]

            data = json.loads(content)

            # Ensure all triggering_data points have a timestamp to prevent Pydantic/Dart crashes
            for rec in data.get("recommendations", []):
                explanation = rec.get("explanation")
                if explanation and isinstance(explanation, dict):
                    for dp in explanation.get("triggering_data", []):
                        if not dp.get("timestamp"):
                            dp["timestamp"] = now_iso

            recommendations = [
                HealthRecommendationItem(**item)
                for item in data.get("recommendations", [])
            ]

            return RecommendationResponse(
                recommendations=recommendations,
                generated_at=data.get("generated_at", now_iso),
                model_used=data.get("model_used", getattr(self.llm, "model_name", "unknown")),
                analysis_period_days=request.analysis_period_days,
            )

        except json.JSONDecodeError as e:
            print(f"[RecommendationService] JSON parse error: {e}")
            raise
        except Exception as e:
            print(f"[RecommendationService] Generation error: {e}")
            raise
