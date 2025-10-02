import pytest
from fastapi.testclient import TestClient
import uuid

from Supabase.client import supabase

# .env file is now loaded by Supabase/client.py
from Supabase.main import app

client = TestClient(app)

@pytest.fixture(scope="session")
def patient_user_payload():
    """
    Generates a unique patient user payload for a test session and returns it.
    This fixture ensures the same user data is used across all tests in the session.
    """
    return {
        "email": f"test.user.{uuid.uuid4()}@example.com",
        "password": "a-very-secure-password-123",
        "role": "PATIENT",
        "name": "Test User",
        "phone_number": "1234567890",
        "emergency_contact_name": "Emergency Contact",
        "emergency_contact_relationship": "Friend",
        "emergency_contact_phone": "0987654321"
    }

@pytest.fixture(scope="session", autouse=True)
def register_test_patient(patient_user_payload):
    """
    A session-scoped fixture that automatically registers a new patient user
    before any tests run. This ensures the user exists for all test modules.
    `autouse=True` ensures it runs automatically for the session.
    """
    response = client.post("/auth/register", json=patient_user_payload)
    assert response.status_code == 200, f"Test setup failed: Could not register user. Response: {response.text}"
    yield
    # Teardown (deleting the user) is not implemented, as it would require
    # exposing a secure admin endpoint or running tests with admin credentials
    # directly against the Supabase client, which complicates the test setup.
    # Using unique emails per test run avoids collisions.


