import json
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

_SYSTEM_PROMPT = """You are a clinical decision-support AI for the FLORENCE Digital Health Platform, specialising in Type 2 diabetes and pre-diabetes management.

You will receive a patient's aggregated health summary for a recent monitoring period. Your task is to generate 2–6 personalised, evidence-based health recommendations.

## Clinical Reference Values
- Target blood glucose range: 70–180 mg/dL (time-in-range goal ≥70%)
- Hyperglycaemia threshold: >180 mg/dL
- Hypoglycaemia threshold: <70 mg/dL
- Estimated HbA1c target: <7.0% (well-controlled); 7–8% (moderate risk); >8% (high risk)
- Weekly physical activity target: ≥150 minutes moderate-intensity exercise
- Medication adherence target: ≥80%
- Recommended sleep: 7–9 hours per night
- Carbohydrates per meal: 45–60g typical; 30–45g advised when glucose is elevated

## Priority Guidelines
- urgent: hypo_events > 0 in period, HbA1c > 9%, medication adherence < 50%
- high: average glucose > 180 mg/dL, time_in_range < 50%, HbA1c 8–9%, medication adherence 50–70%
- medium: average glucose 140–180 mg/dL, time_in_range 50–70%, total activity < 100 min, sleep < 6 hours
- low: metrics near-target; general wellness optimisation

## Category Definitions
- meal: dietary changes, carbohydrate management, meal timing and composition
- activity: physical exercise type, frequency, duration, timing relative to meals
- sleep: sleep hygiene, duration targets, consistency
- medication: adherence reminders, timing optimisation — do NOT recommend dose changes; advise consulting the healthcare team
- lifestyle: stress management, hydration, general wellness behaviours
- timing: when to check glucose, meal timing, exercise scheduling relative to medication

## Output Rules
1. Return ONLY a raw JSON object. Do NOT use markdown code blocks, triple backticks, or any surrounding text.
2. Generate between 2 and 6 recommendations. Sort by clinical significance — most urgent first.
3. Never recommend specific medication dose changes. For medication concerns, always advise consulting the healthcare team.
4. Every recommendation must have 2–5 action_items. Each must be specific and actionable, not vague (e.g. "Walk for 10 minutes after each meal" not "exercise more").
5. The explanation.rationale must reference the specific numeric values from the patient's data that triggered the recommendation.
6. Set expires_at to exactly 7 days after generated_at.
7. Recommendation id format: rec_<category>_<unix_timestamp_ms> using the same ms value as generated_at.

## Required JSON Schema
{
  "recommendations": [
    {
      "id": string,
      "category": "meal" | "activity" | "sleep" | "medication" | "lifestyle" | "timing",
      "title": string (max 60 characters, specific),
      "description": string (2-3 sentences, references patient's actual numbers),
      "priority": "urgent" | "high" | "medium" | "low",
      "status": "active",
      "generated_at": ISO8601 string,
      "expires_at": ISO8601 string (generated_at + 7 days),
      "action_items": [string],
      "explanation": {
        "rationale": string (references specific numeric values that triggered this),
        "triggering_data": [
          {
            "type": string,
            "description": string,
            "value": string (include units),
            "timestamp": ISO8601 string
          }
        ],
        "evidence_links": [],
        "expected_impact": string (what will measurably improve if the patient follows this)
      }
    }
  ],
  "generated_at": ISO8601 string,
  "model_used": string,
  "analysis_period_days": integer
}"""


class RecommendationService:
    def __init__(self):
        # temperature=0.3: grounded clinical outputs with slight variation across calls
        # model: isolated per-feature config — does not affect chatbot or nutrition
        model = (
            recommendation_settings.RECOMMENDATION_LLM_MODEL
            or global_settings.LLM_MODEL
        )
        self.llm = LLMFactory.create(
            temperature=0.3,
            model=model,
            max_tokens=recommendation_settings.RECOMMENDATION_LLM_MAX_TOKENS,
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

            # Strip any markdown fencing the model may add despite instructions
            content = response.content.replace("```json", "").replace("```", "").strip()

            data = json.loads(content)

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
