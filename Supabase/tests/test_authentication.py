import pytest
from fastapi.testclient import TestClient
from dotenv import load_dotenv

# Load .env file from project root, if it exists
load_dotenv()

from Supabase.main import app

client = TestClient(app)

# The patient_user_payload and register_test_patient fixtures are in conftest.py
# and shared across test modules reliably.

def test_login_successful(patient_user_payload):
    """Tests that a registered user can successfully log in."""
    login_credentials = {
        "email": patient_user_payload["email"],
        "password": patient_user_payload["password"]
    }
    response = client.post("/auth/login", json=login_credentials)
    
    assert response.status_code == 200, f"Login failed with correct credentials. Response: {response.text}"
    
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["user"]["email"] == patient_user_payload["email"]

def test_login_failed_wrong_password(patient_user_payload):
    """Tests that login fails when an incorrect password is provided."""
    login_credentials = {
        "email": patient_user_payload["email"],
        "password": "this-is-the-wrong-password"
    }
    response = client.post("/auth/login", json=login_credentials)
    
    assert response.status_code == 401
    assert "Invalid login credentials" in response.json()["detail"]


def test_get_me_successful(patient_user_payload):
    """Tests that an authenticated user can retrieve their own profile."""
    # First, log in to get a token
    login_credentials = {
        "email": patient_user_payload["email"],
        "password": patient_user_payload["password"]
    }
    login_response = client.post("/auth/login", json=login_credentials)
    assert login_response.status_code == 200
    token = login_response.json()["access_token"]

    # Now, use the token to access the /me endpoint
    headers = {"Authorization": f"Bearer {token}"}
    me_response = client.get("/auth/me", headers=headers)

    assert me_response.status_code == 200, f"Failed to get user profile. Response: {me_response.text}"
    
    user_data = me_response.json()
    assert user_data["email"] == patient_user_payload["email"]
    assert "id" in user_data

def test_get_me_failed_invalid_token():
    """Tests that the /me endpoint fails with an invalid token."""
    headers = {"Authorization": "Bearer an-invalid-token"}
    response = client.get("/auth/me", headers=headers)
    
    assert response.status_code == 401
    assert "Invalid token" in response.json()["detail"]

def test_get_me_failed_no_token():
    """Tests that the /me endpoint fails without an authentication token."""
    response = client.get("/auth/me")
    # FastAPI returns 422 Unprocessable Entity if a required header is missing
    assert response.status_code == 422

def test_login_failed_nonexistent_user():
    """Tests that login fails for a user that does not exist."""
    login_credentials = {
        "email": "nonexistent.user@example.com",
        "password": "any-password"
    }
    response = client.post("/auth/login", json=login_credentials)
    
    assert response.status_code == 401
    assert "Invalid login credentials" in response.json()["detail"]
