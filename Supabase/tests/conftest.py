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


# --- Organisation and Clinician Fixtures ---

@pytest.fixture(scope="session")
def test_organisation():
    """Creates a test organisation directly via the Supabase client and cleans up after."""
    org_payload = {"name": f"Test Org {uuid.uuid4()}"}
    response = supabase.table('organisations').insert(org_payload).execute()
    assert len(response.data) > 0, "Failed to create organisation for test setup"
    org_data = response.data[0]
    yield org_data
    # Teardown
    supabase.table('organisations').delete().eq('id', org_data['id']).execute()

@pytest.fixture(scope="session")
def clinician_user_payload(test_organisation):
    """Generates a unique clinician payload."""
    return {
        "email": f"test.clinician.{uuid.uuid4()}@example.com",
        "password": "a-very-secure-clinician-password-123",
        "role": "CLINICIAN",
        "name": "Test Clinician",
        "phone_number": "111222333",
        "organisation_id": test_organisation["id"]
    }

