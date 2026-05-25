import re
from datetime import datetime, timezone
from langchain_core.messages import HumanMessage, SystemMessage
from config import settings as global_settings
from core.llm_factory import LLMFactory
from features.insights.models import InsightRequest, InsightResponse

_SYSTEM_PROMPT = """You are a clinical health assistant for the FLORENCE Digital Health Platform.
Given a patient's health snapshot, generate exactly ONE health insight.

## Rules
1. Output ONLY the insight text — no preamble, no JSON, no bullet points, no labels.
2. Maximum 2 sentences.
3. Always reference specific numbers from the data provided (not generic advice).
4. Always end with one concrete action the patient can take today.
5. Never recommend medication changes.
6. Tone: clear, encouraging, never alarming.

## Priority Order (use the highest applicable signal)
1. Hypo or hyper events — most urgent, mention the count and suggest immediate action
2. Glucose out of range — time-in-range below 70%, mention the percentage
3. No activity today — mention zero minutes and suggest a specific duration
4. Low medication adherence — mention the adherence rate
5. Positive reinforcement — if all signals are good, celebrate with specific numbers

## Clinical Targets (for context)
- Glucose in range: 70–180 mg/dL, target TIR ≥70%
- Activity: ≥30 minutes today
- Medication adherence: ≥80%"""


class InsightService:
    def __init__(self):
        self.llm = LLMFactory.create(
            temperature=0.55,
            model=global_settings.LLM_MODEL,
            max_tokens=256,
        )

    async def generate_insight(self, request: InsightRequest) -> InsightResponse:
        now = datetime.now(timezone.utc)
        s = request.health_snapshot

        # Build human message from snapshot fields
        lines = ["Patient Health Snapshot:"]

        g_val = s.average_glucose_7d or s.latest_glucose or 100.0
        g_unit = "mmol/L" if g_val < 40.0 else "mg/dL"
        g_target = "3.9–10.0 mmol/L" if g_unit == "mmol/L" else "70–180 mg/dL"

        if s.average_glucose_7d is not None:
            lines.append(f"- 7-day average glucose: {s.average_glucose_7d:.1f} {g_unit}")
        if s.latest_glucose is not None:
            lines.append(f"- Latest glucose reading: {s.latest_glucose:.1f} {g_unit}")

        lines.append(f"- Hyperglycaemia events in last 7 days: {s.hyper_events_7d}")
        lines.append(f"- Hypoglycaemia events in last 7 days: {s.hypo_events_7d}")
        lines.append(f"- Time in range ({g_target}): {s.time_in_range_7d * 100:.0f}%")
        lines.append(f"- Activity logged today: {s.activity_minutes_today} minutes")
        lines.append(f"- Meals logged today: {s.meals_today}")
        lines.append(f"- Medication adherence (7-day): {s.medication_adherence_7d * 100:.0f}%")

        if s.latest_bmi is not None:
            lines.append(f"- Latest BMI: {s.latest_bmi:.1f}")
        if s.active_diseases:
            lines.append(f"- Active diagnoses: {', '.join(s.active_diseases)}")

        human_content = "\n".join(lines)

        response = await self.llm.ainvoke([
            SystemMessage(content=_SYSTEM_PROMPT),
            HumanMessage(content=human_content),
        ])

        insight = response.content

        # Strip <think>...</think> blocks (reasoning models like DeepSeek-R1)
        insight = re.sub(r'<think>.*?</think>', '', insight, flags=re.DOTALL)

        # Clean up whitespace
        insight = insight.strip()

        return InsightResponse(
            insight=insight,
            generated_at=now.isoformat(),
        )
