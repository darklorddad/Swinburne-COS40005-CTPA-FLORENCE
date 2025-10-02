import pytest
from fastapi.testclient import TestClient
import uuid
from dotenv import load_dotenv

# Load .env file from project root, if it exists
load_dotenv()

from Supabase.main import app

client = TestClient(app)

# Use a unique email for each test run to prevent conflicts with existing users
unique_email = f"test.user.{uuid.uuid4()}@example.com"
test_user_payload = {
    "email": unique_email,
    "password": "a-very-secure-password-123",
    "role": "PATIENT",
    "name": "Test User",
    "phone_number": "1234567890",
    "emergency_contact_name": "Emergency Contact",
    "emergency_contact_relationship": "Friend",
    "emergency_contact_phone": "0987654321"
}

@pytest.fixture(scope="module", autouse=True)
def register_test_user():
    """
    A fixture that runs once per module to register a user.
    This user can then be used for authentication tests.
    `autouse=True` ensures it runs automatically.
    """
    response = client.post("/auth/register", json=test_user_payload)
    assert response.status_code == 200, f"Test setup failed: Could not register user. Response: {response.text}"
    yield
    # Teardown (deleting the user) is not implemented, as it would require
    # exposing a secure admin endpoint or running tests with admin credentials
    # directly against the Supabase client, which complicates the test setup.
    # Using unique emails per test run avoids collisions.

def test_login_successful():
    """Tests that a registered user can successfully log in."""
    login_credentials = {
        "email": test_user_payload["email"],
        "password": test_user_payload["password"]
    }
    response = client.post("/auth/login", json=login_credentials)
    
    assert response.status_code == 200, f"Login failed with correct credentials. Response: {response.text}"
    
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["user"]["email"] == test_user_payload["email"]

def test_login_failed_wrong_password():
    """Tests that login fails when an incorrect password is provided."""
    login_credentials = {
        "email": test_user_payload["email"],
        "password": "this-is-the-wrong-password"
    }
    response = client.post("/auth/login", json=login_credentials)
    
    assert response.status_code == 401
    assert "Invalid login credentials" in response.json()["detail"]

def test_login_failed_nonexistent_user():
    """Tests that login fails for a user that does not exist."""
    login_credentials = {
        "email": "nonexistent.user@example.com",
        "password": "any-password"
    }
    response = client.post("/auth/login", json=login_credentials)
    
    assert response.status_code == 401
    assert "Invalid login credentials" in response.json()["detail"]
