"""
Shared fixtures for FLORENCE security tests.
"""
import pytest


ENGINE_URL = "https://dev-llmes-florence-dhp.vercel.app"
CHAT_URL = "https://dev-llmcs-florence-dhp.vercel.app"

# Paste your patient JWT here to run chatbot tests (leave as None to skip them)
TEST_TOKEN = None


def minimal_health_summary() -> dict:
    """Returns a valid HealthSummaryRequest dict with safe baseline values."""
    return {
        "average_glucose": 110.0,
        "glucose_std_dev": 10.0,
        "hyper_events": 0,
        "hypo_events": 0,
        "time_in_range": 0.80,
        "estimated_a1c": 5.8,
        "total_meals": 3,
        "average_calories": 500.0,
        "total_activity_minutes": 30,
        "medication_adherence": 0.9,
        "latest_bmi": 23.0,
        "latest_systolic": 118.0,
        "latest_diastolic": 76.0,
        "latest_cholesterol": 180.0,
        "latest_hdl": 55.0,
        "latest_ldl": 95.0,
        "latest_triglycerides": 120.0,
        "latest_hba1c": 5.9,
        "active_diseases": ["Type 2 Diabetes"],
        "current_medications": [
            {"name": "Metformin", "amount": "500mg", "timing": "morning", "type": "oral"}
        ],
        "recent_glucose_readings": [
            {"value": 108.0, "timestamp": "2026-05-08T08:00:00Z"},
            {"value": 115.0, "timestamp": "2026-05-07T08:00:00Z"},
        ],
        "recent_meals": [
            {
                "type": "breakfast",
                "description": "Oats with banana",
                "calories": 350,
                "glucose_before": 105.0,
                "glucose_after": 130.0,
                "timestamp": "2026-05-08T07:30:00Z",
            }
        ],
        "recent_activities": [
            {
                "type": "walking",
                "duration_minutes": 30,
                "calories_burned": 150,
                "timestamp": "2026-05-08T07:00:00Z",
            }
        ],
    }


@pytest.fixture(scope="session")
def engine_url():
    return ENGINE_URL


@pytest.fixture(scope="session")
def chat_url():
    return CHAT_URL


@pytest.fixture(scope="session")
def auth_token():
    return TEST_TOKEN


@pytest.fixture(scope="session")
def health_summary():
    return minimal_health_summary()
