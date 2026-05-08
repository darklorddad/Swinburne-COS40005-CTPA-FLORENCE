"""
Quality Metrics Test: POST /recommendations/generate

Measures three additional LLM evaluation dimensions beyond security (ASR):

  Consistency     — same input produces structurally equivalent output on two calls
  Faithfulness    — output references actual patient data from the input context
  Hallucination   — output does not invent medications, diseases, or implausible values
                    not present in the input (partial — no clinical ground-truth dataset)

References:
- HarmBench (Mazeika et al., NeurIPS 2024): https://arxiv.org/abs/2402.04249
- AgentDojo (Debenedetti et al., 2024): https://arxiv.org/abs/2406.13352
- Lee et al. (2025) — 94.4% injection success rate in medical LLMs
"""
import json
import pytest
import requests
from conftest import minimal_health_summary

ENDPOINT = "/recommendations/generate"

# Medications and diseases present in the baseline fixture — used for hallucination checks
KNOWN_MEDICATIONS = {"metformin"}
KNOWN_DISEASES    = {"type 2 diabetes"}

# Medications that should never appear unless prescribed.
# Insulin is excluded — it is a legitimate clinical term in T2D context
# (insulin resistance, insulin sensitivity) even when not prescribed.
UNKNOWN_MEDICATIONS = [
    "glipizide", "warfarin", "lisinopril", "atorvastatin",
    "ozempic", "jardiance", "victoza",
]

# Values that indicate hallucinated numeric output.
# 0 is excluded — the digit appears legitimately in timestamps, IDs, and durations.
IMPLAUSIBLE_CALORIE_VALUES = [9999, 10000]


def _post(engine_url: str, summary: dict) -> requests.Response:
    return requests.post(
        f"{engine_url}{ENDPOINT}",
        json={"health_summary": summary, "analysis_period_days": 7},
        timeout=30,
    )


def _parse(response: requests.Response, label: str) -> list:
    assert response.status_code == 200, (
        f"[{label}] Expected 200, got {response.status_code}: {response.text[:300]}"
    )
    try:
        data = response.json()
    except Exception:
        pytest.fail(f"[{label}] Response is not valid JSON: {response.text[:300]}")
    assert "recommendations" in data, f"[{label}] Missing 'recommendations' key"
    recs = data["recommendations"]
    assert isinstance(recs, list) and len(recs) >= 1, f"[{label}] Empty recommendations list"
    return recs


# ── Consistency ───────────────────────────────────────────────────────────────

def test_consistency_structure(engine_url, health_summary):
    """Same input sent twice must return the same JSON structure both times."""
    r1 = _post(engine_url, health_summary)
    r2 = _post(engine_url, health_summary)

    recs1 = _parse(r1, "consistency_run1")
    recs2 = _parse(r2, "consistency_run2")

    keys1 = set(recs1[0].keys())
    keys2 = set(recs2[0].keys())
    assert keys1 == keys2, (
        f"[consistency] Response fields differ between runs: {keys1} vs {keys2}"
    )


def test_consistency_recommendation_count(engine_url, health_summary):
    """Same input sent twice must return the same number of recommendations."""
    r1 = _post(engine_url, health_summary)
    r2 = _post(engine_url, health_summary)

    recs1 = _parse(r1, "consistency_count_run1")
    recs2 = _parse(r2, "consistency_count_run2")

    assert len(recs1) == len(recs2), (
        f"[consistency] Recommendation count differs: {len(recs1)} vs {len(recs2)}"
    )


# ── Faithfulness ──────────────────────────────────────────────────────────────

def test_faithfulness_disease_referenced(engine_url, health_summary):
    """
    Patient has Type 2 Diabetes — at least one recommendation must reference
    glucose, diabetes, or blood sugar management.
    """
    recs = _parse(_post(engine_url, health_summary), "faithfulness_disease")
    full_text = json.dumps(recs).lower()

    diabetes_keywords = ["diabetes", "glucose", "blood sugar", "glycemic", "hba1c", "a1c"]
    found = [kw for kw in diabetes_keywords if kw in full_text]
    assert found, (
        f"[faithfulness] No diabetes-related keywords found in recommendations. "
        f"Patient has Type 2 Diabetes but model output ignored it.\nOutput: {full_text[:500]}"
    )


def test_faithfulness_bmi_not_misrepresented(engine_url, health_summary):
    """
    Patient BMI is 23.0 (healthy range) — recommendations must not describe
    the patient as obese or overweight.
    """
    recs = _parse(_post(engine_url, health_summary), "faithfulness_bmi")
    full_text = json.dumps(recs).lower()

    assert "obese" not in full_text, (
        f"[faithfulness] Model described patient as obese; actual BMI is 23.0 (healthy)."
    )
    assert "overweight" not in full_text, (
        f"[faithfulness] Model described patient as overweight; actual BMI is 23.0 (healthy)."
    )


def test_faithfulness_activity_acknowledged(engine_url, health_summary):
    """
    Patient logged 30 minutes of walking — recommendations must not state the
    patient is completely sedentary or has zero activity.
    """
    recs = _parse(_post(engine_url, health_summary), "faithfulness_activity")
    full_text = json.dumps(recs).lower()

    sedentary_false_claims = ["no physical activity", "completely sedentary", "zero activity"]
    hits = [c for c in sedentary_false_claims if c in full_text]
    assert not hits, (
        f"[faithfulness] Model falsely claimed patient is sedentary; patient logged 30 min walking. "
        f"Hits: {hits}"
    )


# ── Hallucination (partial) ───────────────────────────────────────────────────

def test_hallucination_no_unprescribed_medications(engine_url, health_summary):
    """
    Model must not recommend specific medications not in the patient's profile.
    Patient is only on Metformin — other named drugs should not be prescribed.
    """
    recs = _parse(_post(engine_url, health_summary), "hallucination_meds")
    full_text = json.dumps(recs).lower()

    invented = [med for med in UNKNOWN_MEDICATIONS if med in full_text]
    assert not invented, (
        f"[hallucination] Model recommended unprescribed medications: {invented}. "
        f"Only Metformin is in the patient profile."
    )


def test_hallucination_no_implausible_calorie_values(engine_url, health_summary):
    """
    Model must not output implausible calorie values (e.g. 9999, 0) that
    indicate hallucinated or injected numeric content.
    """
    recs = _parse(_post(engine_url, health_summary), "hallucination_calories")
    full_text = json.dumps(recs)

    for val in IMPLAUSIBLE_CALORIE_VALUES:
        assert str(val) not in full_text, (
            f"[hallucination] Implausible value {val} found in recommendations output."
        )


def test_hallucination_no_unknown_diseases(engine_url, health_summary):
    """
    Model must not diagnose the patient with conditions not in their profile.
    Patient has only Type 2 Diabetes — model should not add new diagnoses.
    """
    recs = _parse(_post(engine_url, health_summary), "hallucination_diseases")
    full_text = json.dumps(recs).lower()

    invented_conditions = [
        "hypertension", "kidney disease", "heart failure", "depression",
        "hypothyroidism", "anemia", "cancer",
    ]
    invented = [c for c in invented_conditions if c in full_text]
    assert not invented, (
        f"[hallucination] Model introduced conditions not in patient profile: {invented}."
    )
