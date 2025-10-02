import pytest
from fastapi.testclient import TestClient
import uuid
from dotenv import load_dotenv

from Supabase.client import supabase

# Load .env file from project root, if it exists
load_dotenv()

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


# --- Admin Fixtures ---

@pytest.fixture(scope="session")
def admin_user_payload():
    """Generates a unique admin user payload."""
    return {
        "email": f"test.admin.{uuid.uuid4()}@example.com",
        "password": "a-very-secure-admin-password-123",
    }

@pytest.fixture(scope="session")
def registered_admin_user(admin_user_payload):
    """Creates an admin user directly via Supabase client and cleans up after."""
    user = None
    try:
        user_res = supabase.auth.admin.create_user({
            "email": admin_user_payload["email"],
            "password": admin_user_payload["password"],
            "email_confirm": True,
            "user_metadata": {"role": "ADMIN"},
        })
        user = user_res.user
        yield user
    finally:
        # Teardown: delete the admin user
        if user:
            supabase.auth.admin.delete_user(user.id)

@pytest.fixture(scope="session")
def admin_token(registered_admin_user, admin_user_payload):
    """Logs in the admin user and returns an auth token."""
    login_credentials = {
        "email": admin_user_payload["email"],
        "password": admin_user_payload["password"]
    }
    response = client.post("/auth/login", json=login_credentials)
    assert response.status_code == 200, f"Failed to log in as admin for test setup: {response.text}"
    return response.json()["access_token"]


# --- Organisation and Clinician Fixtures ---

@pytest.fixture(scope="session")
def test_organisation():
    """Creates a test organisation and cleans up after."""
    org_payload = {"name": f"Test Org {uuid.uuid4()}"}
    response = client.post("/insert/organisations", json=org_payload)
    assert response.status_code == 200, f"Failed to create organisation for test setup: {response.text}"
    org_data = response.json()["data"][0]
    yield org_data
    # Teardown
    client.delete(f"/delete/organisations/{org_data['id']}")

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

@pytest.fixture(scope="session")
def registered_clinician(clinician_user_payload):
    """Registers a clinician user and returns their profile from the DB."""
    response = client.post("/auth/register", json=clinician_user_payload)
    assert response.status_code == 200, f"Failed to register clinician for test setup: {response.text}"
    
    # Log in to get the profile via /me endpoint
    login_resp = client.post("/auth/login", json={"email": clinician_user_payload["email"], "password": clinician_user_payload["password"]})
    assert login_resp.status_code == 200, f"Failed to log in as new clinician: {login_resp.text}"
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    profile_resp = client.get("/clinicians/me", headers=headers)
    assert profile_resp.status_code == 200, f"Failed to fetch new clinician's profile: {profile_resp.text}"
    
    yield profile_resp.json()
    # Teardown of user is not implemented, following project convention.

@pytest.fixture(scope="session")
def clinician_token(clinician_user_payload):
    """Logs in the clinician and returns an auth token."""
    login_credentials = {
        "email": clinician_user_payload["email"],
        "password": clinician_user_payload["password"]
    }
    response = client.post("/auth/login", json=login_credentials)
    assert response.status_code == 200, f"Failed to log in as clinician for test setup: {response.text}"
    return response.json()["access_token"]


# --- Patient Fixture for Clinician/Admin tests ---

@pytest.fixture(scope="session")
def managed_patient(admin_token, registered_clinician):
    """
    Creates a new patient and assigns them to the test clinician.
    Returns the full patient profile of the assigned patient.
    """
    patient_payload = {
        "email": f"test.managed.patient.{uuid.uuid4()}@example.com",
        "password": "a-secure-patient-password-123",
        "role": "PATIENT",
        "name": "Managed Patient",
        "phone_number": "555444333"
    }
    reg_response = client.post("/auth/register", json=patient_payload)
    assert reg_response.status_code == 200, f"Failed to register patient for management tests: {reg_response.text}"

    admin_headers = {"Authorization": f"Bearer {admin_token}"}
    all_patients_resp = client.get("/admin/patients", headers=admin_headers)
    assert all_patients_resp.status_code == 200
    all_patients = all_patients_resp.json()
    
    new_patient_profile = next((p for p in all_patients if p["name"] == "Managed Patient" and p["clinician_id"] is None), None)
    assert new_patient_profile is not None, "Failed to find newly created patient for assignment."
    patient_id = new_patient_profile["id"]

    assign_payload = {"clinician_id": registered_clinician["id"]}
    assign_resp = client.put(f"/admin/patients/{patient_id}/assign-clinician", json=assign_payload, headers=admin_headers)
    assert assign_resp.status_code == 200, f"Failed to assign patient to clinician: {assign_resp.text}"
    
    yield assign_resp.json()[0]
