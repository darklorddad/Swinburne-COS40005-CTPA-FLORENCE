import pytest
from fastapi.testclient import TestClient

from Supabase.main import app

client = TestClient(app)

def test_clinician_registration_and_profile_retrieval(clinician_user_payload):
    """
    Tests the full registration, login, and profile retrieval flow for a clinician.
    """
    # 1. Register the clinician
    reg_response = client.post("/auth/register", json=clinician_user_payload)
    assert reg_response.status_code == 200, f"Clinician registration failed: {reg_response.text}"
    assert "Clinician registered successfully" in reg_response.json()["message"]

    # 2. Log in as the newly registered clinician
    login_credentials = {
        "email": clinician_user_payload["email"],
        "password": clinician_user_payload["password"]
    }
    login_response = client.post("/auth/login", json=login_credentials)
    assert login_response.status_code == 200, f"Clinician login failed: {login_response.text}"
    token = login_response.json()["access_token"]
    assert token is not None

    # 3. Retrieve the clinician's own profile
    headers = {"Authorization": f"Bearer {token}"}
    profile_response = client.get("/clinicians/me", headers=headers)
    assert profile_response.status_code == 200, f"Failed to get clinician profile: {profile_response.text}"
    
    profile = profile_response.json()
    assert profile["name"] == clinician_user_payload["name"]
    assert profile["phone_number"] == clinician_user_payload["phone_number"]
    assert profile["organisation_id"] == clinician_user_payload["organisation_id"]
    assert profile["user_id"] is not None

def test_register_clinician_fails_without_organisation(clinician_user_payload):
    """
    Tests that clinician registration fails with a 400 error if organisation_id is missing.
    """
    bad_payload = clinician_user_payload.copy()
    del bad_payload["organisation_id"]
    
    response = client.post("/auth/register", json=bad_payload)
    assert response.status_code == 400
    assert "Organisation ID is required for clinicians" in response.json()["detail"]
