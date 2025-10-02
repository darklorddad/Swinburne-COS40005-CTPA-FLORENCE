import pytest
from fastapi.testclient import TestClient
from dotenv import load_dotenv
from datetime import datetime, timezone

# Load .env file from project root, if it exists
load_dotenv()

from Supabase.main import app
# The patient_user_payload is now injected from the fixture in conftest.py

client = TestClient(app)

@pytest.fixture(scope="module")
def authenticated_patient_token(patient_user_payload):
    """
    Fixture to log in the test patient and provide an auth token.
    This relies on the session-scoped `register_test_patient` fixture
    in `conftest.py` having already run.
    """
    login_credentials = {
        "email": patient_user_payload["email"],
        "password": patient_user_payload["password"]
    }
    response = client.post("/auth/login", json=login_credentials)
    assert response.status_code == 200, f"Failed to log in test patient: {response.text}"
    return response.json()["access_token"]

def test_get_own_patient_profile(authenticated_patient_token, patient_user_payload):
    """Tests that a patient can retrieve their own profile."""
    headers = {"Authorization": f"Bearer {authenticated_patient_token}"}
    response = client.get("/patients/me", headers=headers)
    
    assert response.status_code == 200
    profile = response.json()
    assert profile["name"] == patient_user_payload["name"]
    assert profile["phone_number"] == patient_user_payload["phone_number"]
    assert profile["user_id"] is not None

def test_update_own_patient_profile(authenticated_patient_token):
    """Tests that a patient can update their own profile information."""
    headers = {"Authorization": f"Bearer {authenticated_patient_token}"}
    update_payload = {
        "name": "Updated Test User Name",
        "emergency_contact_name": "New Emergency Contact"
    }
    response = client.put("/patients/me", headers=headers, json=update_payload)
    
    assert response.status_code == 200
    updated_profile = response.json()
    assert updated_profile["name"] == "Updated Test User Name"
    assert updated_profile["emergency_contact_name"] == "New Emergency Contact"

    # Verify the change persists by fetching the profile again
    get_response = client.get("/patients/me", headers=headers)
    assert get_response.status_code == 200
    assert get_response.json()["name"] == "Updated Test User Name"

def test_patient_monitor_data_crud_flow(authenticated_patient_token):
    """Tests the full create, read, and update flow for patient monitor data."""
    headers = {"Authorization": f"Bearer {authenticated_patient_token}"}
    
    # 1. POST: Add a new glucose reading
    post_payload = {
        "data_type": "GLUCOSE",
        "value": 120.5,
        "measured_at": datetime.now(timezone.utc).isoformat()
    }
    post_response = client.post("/patients/me/monitor-data", headers=headers, json=post_payload)
    assert post_response.status_code == 200, f"Failed to post monitor data: {post_response.text}"
    new_data = post_response.json()
    assert new_data["data_type"] == "GLUCOSE"
    assert new_data["value"] == 120.5
    data_id = new_data["id"]

    # 2. GET: Retrieve all data and verify the new entry is present
    get_response = client.get("/patients/me/monitor-data", headers=headers)
    assert get_response.status_code == 200
    all_data = get_response.json()
    assert any(d["id"] == data_id for d in all_data)

    # 3. PUT: Update the value of the new data entry
    put_payload = {"value": 125.0}
    put_response = client.put(f"/patients/me/monitor-data/{data_id}", headers=headers, json=put_payload)
    assert put_response.status_code == 200, f"Failed to update monitor data: {put_response.text}"
    updated_data = put_response.json()
    assert updated_data["value"] == 125.0

    # 4. Verify the update persisted
    get_response_after_update = client.get("/patients/me/monitor-data", headers=headers)
    assert get_response_after_update.status_code == 200
    updated_item = next((d for d in get_response_after_update.json() if d["id"] == data_id), None)
    assert updated_item is not None
    assert updated_item["value"] == 125.0

def test_patient_daily_logs_crud_flow(authenticated_patient_token):
    """Tests the create and read flow for patient daily logs."""
    headers = {"Authorization": f"Bearer {authenticated_patient_token}"}
    log_date = datetime.now(timezone.utc).date().isoformat()

    # 1. POST: Add a new daily log
    post_payload = {
        "log_date": log_date,
        "meal_time": "BREAKFAST",
        "glucose_before_meal": 95.0
    }
    post_response = client.post("/patients/me/daily-logs", headers=headers, json=post_payload)
    assert post_response.status_code == 200, f"Failed to post daily log: {post_response.text}"
    new_log = post_response.json()
    assert new_log["log_date"] == log_date
    assert new_log["meal_time"] == "BREAKFAST"
    assert new_log["glucose_before_meal"] == 95.0

    # 2. GET: Retrieve all logs and verify the new one is there
    get_response = client.get("/patients/me/daily-logs", headers=headers)
    assert get_response.status_code == 200
    all_logs = get_response.json()
    assert any(log["id"] == new_log["id"] for log in all_logs)

    # 3. POST (Failure): Try to add a duplicate log
    duplicate_response = client.post("/patients/me/daily-logs", headers=headers, json=post_payload)
    assert duplicate_response.status_code == 409, f"Expected 409 Conflict on duplicate log, but got {duplicate_response.status_code}"

def test_get_own_thresholds(authenticated_patient_token):
    """Tests that a patient can retrieve their health thresholds."""
    headers = {"Authorization": f"Bearer {authenticated_patient_token}"}
    response = client.get("/patients/me/thresholds", headers=headers)
    
    assert response.status_code == 200
    thresholds = response.json()
    # The registration process automatically creates default thresholds
    assert isinstance(thresholds, list)
    assert len(thresholds) > 0
    assert any(t["data_type"] == "GLUCOSE" for t in thresholds)

def test_patient_endpoints_fail_without_token():
    """Tests that patient endpoints fail correctly without an auth token."""
    response = client.get("/patients/me")
    # FastAPI returns 422 if a required header is missing
    assert response.status_code == 422

def test_patient_endpoints_fail_with_invalid_token():
    """Tests that patient endpoints fail correctly with a bad auth token."""
    headers = {"Authorization": "Bearer an-invalid-token-that-will-not-work"}
    response = client.get("/patients/me", headers=headers)
    assert response.status_code == 401
    assert "Invalid token" in response.json()["detail"]
