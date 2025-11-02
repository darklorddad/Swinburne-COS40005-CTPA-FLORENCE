import pytest
from fastapi.testclient import TestClient
import os
import uuid
from datetime import date
import sys
from pathlib import Path

# Add the project root to the Python path to resolve imports
project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

# The app is imported here.
from Supabase.main import app

# Load environment variables from .env file for tests
from dotenv import load_dotenv

load_dotenv(dotenv_path=project_root / '.env', override=True)

client = TestClient(app)

# --- Test Data ---
# Use UUID to ensure unique emails for each test run, avoiding conflicts
unique_id = uuid.uuid4().hex[:8]
PATIENT_EMAIL = f"test.patient.{unique_id}@example.com"
CLINICIAN_EMAIL = f"test.clinician.{unique_id}@example.com"
PASSWORD = "a-very-secure-password123"

# Admin credentials must be provided via environment variables for security
ADMIN_EMAIL = os.environ.get("TEST_ADMIN_EMAIL")
ADMIN_PASSWORD = os.environ.get("TEST_ADMIN_PASSWORD")

# --- Fixtures ---
@pytest.fixture(scope="module")
def test_patient_credentials():
    """Provides credentials for a test patient."""
    return {"email": PATIENT_EMAIL, "password": PASSWORD}

@pytest.fixture(scope="module")
def admin_auth_header():
    """Logs in as admin and provides the auth header, skipping tests if creds are missing."""
    if not ADMIN_EMAIL or not ADMIN_PASSWORD:
        pytest.skip("Admin test credentials (TEST_ADMIN_EMAIL, TEST_ADMIN_PASSWORD) not provided in .env file")
    
    response = client.post("/auth/login", json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD})
    if response.status_code != 200:
        pytest.fail(f"Admin login failed, cannot proceed with tests that depend on it. Status: {response.status_code}, Detail: {response.text}")

    access_token = response.json()["access_token"]
    return {"Authorization": f"Bearer {access_token}"}


@pytest.fixture(scope="module")
def test_clinician_credentials(admin_auth_header):
    """
    Provides credentials for a test clinician after creating a new organisation for them.
    """
    # Create a new organisation for this test run
    org_name = f"Test-Org-{unique_id}"
    response = client.post("/admin/organisations", json={"name": org_name}, headers=admin_auth_header)
    assert response.status_code == 200, f"Failed to create test organisation: {response.text}"
    org_id = response.json()["id"]

    return {
        "email": CLINICIAN_EMAIL,
        "password": PASSWORD,
        "organisation_id": org_id
    }

# --- Test Cases ---

def test_register_patient(test_patient_credentials):
    """Tests that a new patient can be registered via the public endpoint."""
    response = client.post("/auth/register", json={
        "email": test_patient_credentials["email"],
        "password": test_patient_credentials["password"],
        "role": "PATIENT",
        "name": "Test Patient",
        "phone_number": "123456789",
        "date_of_birth": date(1990, 1, 1).isoformat(),
        "gender": "Female",
        "emergency_contact_name": "Jane Doe",
        "emergency_contact_relationship": "Spouse",
        "emergency_contact_phone": "111222333"
    })
    assert response.status_code == 200, response.text
    assert "Patient registered successfully" in response.json()["message"]

def test_register_clinician(test_clinician_credentials):
    """Tests that a new clinician can be registered via the public endpoint."""
    response = client.post("/auth/register", json={
        "email": test_clinician_credentials["email"],
        "password": test_clinician_credentials["password"],
        "role": "CLINICIAN",
        "name": "Test Clinician",
        "phone_number": "987654321",
        "organisation_id": test_clinician_credentials["organisation_id"],
        "gender": "Male"
    })
    assert response.status_code == 200, response.text
    assert "Clinician registered successfully" in response.json()["message"]

@pytest.mark.depends(on=['test_register_patient'])
def test_login_patient(test_patient_credentials):
    """Tests that a newly registered patient can log in."""
    response = client.post("/auth/login", json={
        "email": test_patient_credentials["email"],
        "password": test_patient_credentials["password"]
    })
    assert response.status_code == 200, response.text
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"

@pytest.mark.depends(on=['test_register_clinician'])
def test_login_clinician(test_clinician_credentials):
    """Tests that a newly registered clinician can log in."""
    response = client.post("/auth/login", json={
        "email": test_clinician_credentials["email"],
        "password": test_clinician_credentials["password"]
    })
    assert response.status_code == 200, response.text
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"

@pytest.mark.skipif(not ADMIN_EMAIL or not ADMIN_PASSWORD, reason="Admin test credentials (TEST_ADMIN_EMAIL, TEST_ADMIN_PASSWORD) not provided in .env file")
def test_login_admin():
    """Tests that a pre-existing admin can log in."""
    response = client.post("/auth/login", json={
        "email": ADMIN_EMAIL,
        "password": ADMIN_PASSWORD
    })
    assert response.status_code == 200, response.text
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"
