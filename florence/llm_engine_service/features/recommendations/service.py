import json
import re
from datetime import datetime, timezone
from langchain_core.messages import HumanMessage, SystemMessage
from config import settings as global_settings
from core.ds_client import fetch_user_settings, fetch_user_thresholds
from core.llm_factory import LLMFactory
from features.recommendations.rec_config import recommendation_settings
from features.recommendations.models import (
    RecommendationRequest,
    RecommendationResponse,
    HealthRecommendationItem,
)

_SYSTEM_PROMPT = """You are a clinical decision-support AI for the FLORENCE Digital Health Platform.
You will receive a patient's health summary and their personalised clinical targets.
Generate 0 to 3 concise, evidence-based health recommendations.

## Output Rules
1. Return ONLY raw JSON. No markdown, no backticks, no conversational text.
2. Follow the requested quantity rules strictly. Sort by urgency.
3. Never recommend dose changes.
4. NEVER hallucinate or change the units provided. If the input is in mmol/L, your output MUST be in mmol/L. Do not mentally convert to mg/dL.
5. Each recommendation needs 2 specific action_items.
6. Keep descriptions and rationales under 200 characters each.
7. In triggering_data, cite specific readings from the patient's individual data when available. Use the type field as a machine key and description as human-readable label.
8. Set expires_at to 7 days after generated_at.
9. ID format: rec_<category>_<timestamp_ms>.

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
            temperature=0.65,
            model=model,
            max_tokens=recommendation_settings.LLM_MAX_TOKENS,
        )

    async def generate_recommendations(
        self, request: RecommendationRequest, token: str
    ) -> RecommendationResponse:
        now = datetime.now(timezone.utc)
        now_iso = now.isoformat()
        s = request.health_summary

        # Fetch real user preferences and thresholds from the Data Service
        settings_data = await fetch_user_settings(token)
        thresholds_data = await fetch_user_thresholds(token)

        g_unit = settings_data.get("glucose_unit", "mmol/L")
        c_unit = settings_data.get("cholesterol_unit", "mmol/L")

        # Map thresholds for easy lookup (DS already returns these in the user's preferred unit)
        thresh_map = {t['data_type'].upper(): t for t in thresholds_data if 'data_type' in t}

        # Build dynamic targets based on the user's actual database thresholds
        g_thresh = thresh_map.get('GLUCOSE', {})
        g_min = g_thresh.get('min_value', 3.9 if g_unit == 'mmol/L' else 70.0)
        g_max = g_thresh.get('max_value', 10.0 if g_unit == 'mmol/L' else 180.0)
        g_target = f"{g_min}–{g_max} {g_unit}"

        hdl_thresh = thresh_map.get('CHOLESTEROL_HDL', {})
        hdl_min = hdl_thresh.get('min_value', 1.0 if c_unit == 'mmol/L' else 40.0)
        hdl_target = f">{hdl_min} {c_unit}"

        ldl_thresh = thresh_map.get('CHOLESTEROL_LDL', {})
        ldl_max = ldl_thresh.get('max_value', 2.6 if c_unit == 'mmol/L' else 100.0)
        ldl_target = f"<{ldl_max} {c_unit}"

        trig_thresh = thresh_map.get('CHOLESTEROL_TRIGLYCERIDES', {})
        trig_max = trig_thresh.get('max_value', 1.7 if c_unit == 'mmol/L' else 150.0)
        trig_target = f"<{trig_max} {c_unit}"

        # Build extended vitals section
        extended_lines = []
        if s.latest_bmi is not None:
            extended_lines.append(f"- Latest BMI: {s.latest_bmi:.1f}")
        if s.latest_systolic is not None and s.latest_diastolic is not None:
            extended_lines.append(f"- Latest Blood Pressure: {s.latest_systolic:.0f}/{s.latest_diastolic:.0f} mmHg")
        if s.latest_cholesterol is not None:
            extended_lines.append(f"- Latest Total Cholesterol: {s.latest_cholesterol:.1f} {c_unit}")
        if s.latest_hdl is not None:
            extended_lines.append(f"- Latest HDL Cholesterol: {s.latest_hdl:.1f} {c_unit}")
        if s.latest_ldl is not None:
            extended_lines.append(f"- Latest LDL Cholesterol: {s.latest_ldl:.1f} {c_unit}")
        if s.latest_triglycerides is not None:
            extended_lines.append(f"- Latest Triglycerides: {s.latest_triglycerides:.1f} {c_unit}")
        if s.latest_hba1c is not None:
            extended_lines.append(f"- Latest Lab HbA1c: {s.latest_hba1c:.1f}%")
        extended_section = ("\n" + "\n".join(extended_lines)) if extended_lines else ""

        # Disease & medication context
        disease_section = ""
        if s.active_diseases:
            disease_section = f"\nActive Diagnoses: {', '.join(s.active_diseases)}"

        medication_section = ""
        if s.current_medications:
            rows = "\n".join(
                f"  - {m.get('name','Unknown')} {m.get('amount','')} ({m.get('type','')}) — take {m.get('timing','')}"
                for m in s.current_medications
            )
            medication_section = f"\nCurrent Medications:\n{rows}"

        # Build recent readings sections
        glucose_section = ""
        if s.recent_glucose_readings:
            rows = "\n".join(
                f"  {r['timestamp']}: {r['value']} {g_unit}"
                for r in s.recent_glucose_readings
            )
            glucose_section = f"\nRecent Glucose Readings (newest first):\n{rows}"

        meal_section = ""
        if s.recent_meals:
            rows = "\n".join(
                f"  {m.get('type','Meal')} at {m['timestamp']}"
                + (f": {m['description']}" if m.get('description') else "")
                + (f", {m.get('calories',0)} kcal" if m.get('calories') else "")
                + (f", glucose {m['glucose_before']}→{m['glucose_after']} {g_unit}"
                   if m.get('glucose_before') and m.get('glucose_after') else "")
                for m in s.recent_meals
            )
            meal_section = f"\nRecent Meals:\n{rows}"

        activity_section = ""
        if s.recent_activities:
            rows = "\n".join(
                f"  {a.get('type','Activity')} {a.get('duration_minutes',0)}min at {a['timestamp']}"
                + (f", {a['calories_burned']} kcal burned" if a.get('calories_burned') else "")
                for a in s.recent_activities
            )
            activity_section = f"\nRecent Activities:\n{rows}"

        # Previous recommendations to avoid repetition
        prev_section = ""
        if request.previous_recommendation_titles:
            titles = "\n".join(f"  - {t}" for t in request.previous_recommendation_titles)
            prev_section = f"\nIMPORTANT: The patient has already received these recommendations — do NOT repeat them, generate fresh ones:\n{titles}"

        if request.analysis_period_days == 1:
            quantity_rule = "\nCRITICAL RULE FOR DAILY: Generate between 0 and 3 tactical recommendations based on today's data. If all metrics are perfectly in range and goals are met, output an empty list `[]` for 'recommendations'. Do not force a recommendation if the patient is doing perfectly."
        else:
            quantity_rule = "\nCRITICAL RULE FOR WEEKLY: Generate exactly 0 or 1 strategic recommendation focusing on macro-trends over the last 7 days. Only output 0 if there is absolutely no data for the week."

        human_content = f"""Please generate health recommendations for a patient with the following {request.analysis_period_days}-day health summary.{quantity_rule}

## Clinical Targets (in patient's preferred units)
- Glucose Target Range: {g_target}
- HbA1c Target: <7.0%
- Activity Target: ≥150 min/week
- Adherence Target: ≥80%
- HDL Cholesterol Target: {hdl_target}
- LDL Cholesterol Target: {ldl_target}
- Triglycerides Target: {trig_target}

Patient Health Summary ({request.analysis_period_days}-day period):
- Average Blood Glucose: {s.average_glucose:.1f} {g_unit}
- Glucose Variability (Std Dev): {s.glucose_std_dev:.1f} {g_unit}
- Hyperglycaemia Events: {s.hyper_events}
- Hypoglycaemia Events: {s.hypo_events}
- Time in Target Range ({g_target}): {s.time_in_range:.1f}%
- Estimated HbA1c: {s.estimated_a1c:.1f}%
- Total Meals Logged: {s.total_meals}
- Average Calories per Meal: {s.average_calories:.0f} kcal
- Total Activity Minutes: {s.total_activity_minutes} minutes
- Medication Adherence (today): {s.medication_adherence * 100:.0f}%{extended_section}{disease_section}{medication_section}{glucose_section}{meal_section}{activity_section}{prev_section}

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
