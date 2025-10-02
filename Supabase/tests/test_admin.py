import pytest
from fastapi.testclient import TestClient
import uuid

from Supabase.main import app

client = TestClient(app)

# Fixtures `admin_token`, `patient_user_payload`, `registered_clinician`, `clinician_token` are from conftest.py

def test_admin_endpoints_unauthorized(clinician_token):
    """Tests that a non-admin user (e.g., clinician) cannot access admin endpoints."""
    headers = {"Authorization": f"Bearer {clinician_token}"}

    # Try to access various admin endpoints
    response_get = client.get("/admin/patients", headers=headers)
    assert response_get.status_code == 403, "GET /admin/patients should be forbidden for non-admins"

    response_put = client.put("/admin/patients/999", json={}, headers=headers)
    assert response_put.status_code == 403, "PUT /admin/patients/{id} should be forbidden for non-admins"

def test_register_admin_by_admin(admin_token):
    """Tests that an admin can successfully register another admin."""
    new_admin_payload = {
        "email": f"new.admin.{uuid.uuid4()}@example.com",
        "password": "new-admin-password"
    }
    headers = {"Authorization": f"Bearer {admin_token}"}
    response = client.post("/auth/register_admin", json=new_admin_payload, headers=headers)
    assert response.status_code == 200
    assert response.json()["message"] == "Admin registered successfully."

def test_get_all_patients(admin_token, patient_user_payload):
    """Tests that an admin can retrieve a list of all patients."""
    headers = {"Authorization": f"Bearer {admin_token}"}
    response = client.get("/admin/patients", headers=headers)
    assert response.status_code == 200
    patients = response.json()
    assert isinstance(patients, list)
    # Check if the auto-registered patient from conftest is in the list
    assert any(p['name'] == patient_user_payload['name'] for p in patients)

def test_admin_patient_management_flow(admin_token, registered_clinician):
    """Tests the full admin flow: create, update, assign, unassign, and delete a patient."""
    headers = {"Authorization": f"Bearer {admin_token}"}
    
    # 1. Create a patient to manage (using the public registration endpoint)
    patient_payload = {
        "email": f"admin.managed.patient.{uuid.uuid4()}@example.com",
        "password": "a-secure-password",
        "role": "PATIENT",
        "name": "Admin Managed Patient",
        "phone_number": "123123123"
    }
    reg_response = client.post("/auth/register", json=patient_payload)
    assert reg_response.status_code == 200, f"Failed to register patient for admin test: {reg_response.text}"

    # 2. Find the newly created patient's ID
    all_patients_resp = client.get("/admin/patients", headers=headers)
    patient_profile = next((p for p in all_patients_resp.json() if p["name"] == "Admin Managed Patient"), None)
    assert patient_profile is not None, "Failed to find newly created patient in all_patients list."
    patient_id = patient_profile["id"]

    # 3. Update the patient's profile
    update_payload = {"name": "Admin Updated Name", "risk_level": "HIGH"}
    update_resp = client.put(f"/admin/patients/{patient_id}", json=update_payload, headers=headers)
    assert update_resp.status_code == 200
    assert update_resp.json()[0]["name"] == "Admin Updated Name"
    assert update_resp.json()[0]["risk_level"] == "HIGH"

    # 4. Assign a clinician
    assign_payload = {"clinician_id": registered_clinician["id"]}
    assign_resp = client.put(f"/admin/patients/{patient_id}/assign-clinician", json=assign_payload, headers=headers)
    assert assign_resp.status_code == 200
    assert assign_resp.json()[0]["clinician_id"] == registered_clinician["id"]

    # 5. Unassign the clinician
    unassign_payload = {"clinician_id": None}
    unassign_resp = client.put(f"/admin/patients/{patient_id}/assign-clinician", json=unassign_payload, headers=headers)
    assert unassign_resp.status_code == 200
    assert unassign_resp.json()[0]["clinician_id"] is None

    # 6. Delete the patient profile
    delete_resp = client.delete(f"/admin/patients/{patient_id}", headers=headers)
    assert delete_resp.status_code == 200
    assert "deleted successfully" in delete_resp.json()["message"]

    # 7. Verify deletion
    get_resp = client.get(f"/admin/patients", headers=headers)
    assert not any(p["id"] == patient_id for p in get_resp.json())
