import pytest
from fastapi.testclient import TestClient

from Supabase.main import app

client = TestClient(app)

# Fixtures from conftest: `clinician_token`, `registered_clinician`, `managed_patient`, `patient_user_payload`

def test_get_own_clinician_profile(clinician_token, registered_clinician):
    """Tests that a clinician can retrieve their own profile."""
    headers = {"Authorization": f"Bearer {clinician_token}"}
    response = client.get("/clinicians/me", headers=headers)
    assert response.status_code == 200
    profile = response.json()
    assert profile["id"] == registered_clinician["id"]
    assert profile["name"] == registered_clinician["name"]

def test_get_assigned_patients(clinician_token, managed_patient):
    """Tests that a clinician can retrieve a list of their assigned patients."""
    headers = {"Authorization": f"Bearer {clinician_token}"}
    response = client.get("/clinicians/me/patients", headers=headers)
    assert response.status_code == 200
    patients = response.json()
    assert isinstance(patients, list)
    assert len(patients) >= 1
    assert any(p["id"] == managed_patient["id"] for p in patients)

def test_get_assigned_patient_details(clinician_token, managed_patient):
    """Tests that a clinician can retrieve the full details of an assigned patient."""
    patient_id = managed_patient["id"]
    headers = {"Authorization": f"Bearer {clinician_token}"}
    response = client.get(f"/clinicians/me/patients/{patient_id}", headers=headers)
    assert response.status_code == 200
    details = response.json()
    assert details["profile"]["id"] == patient_id
    assert "monitor_data" in details
    assert "daily_logs" in details
    assert "thresholds" in details
    assert "notes" in details

def test_clinician_cannot_access_unassigned_patient(clinician_token, patient_user_payload):
    """
    Tests that a clinician receives a 404 when trying to access a patient
    that is not assigned to them.
    """
    # We need the ID of an unassigned patient. The one from `patient_user_payload` is unassigned.
    # We must fetch its profile ID first.
    login_resp = client.post("/auth/login", json={"email": patient_user_payload["email"], "password": patient_user_payload["password"]})
    patient_token = login_resp.json()["access_token"]
    patient_profile_resp = client.get("/patients/me", headers={"Authorization": f"Bearer {patient_token}"})
    unassigned_patient_id = patient_profile_resp.json()["id"]

    headers = {"Authorization": f"Bearer {clinician_token}"}
    response = client.get(f"/clinicians/me/patients/{unassigned_patient_id}", headers=headers)
    assert response.status_code == 404
    assert "not found or not assigned" in response.json()["detail"]

def test_clinician_patient_management_flow(clinician_token, managed_patient):
    """Tests the clinician's workflow for managing an assigned patient."""
    patient_id = managed_patient["id"]
    headers = {"Authorization": f"Bearer {clinician_token}"}

    # 1. Assess risk
    risk_payload = {"risk_level": "MEDIUM"}
    risk_resp = client.put(f"/clinicians/me/patients/{patient_id}/assess-risk", json=risk_payload, headers=headers)
    assert risk_resp.status_code == 200, f"Failed to assess risk: {risk_resp.text}"
    assert risk_resp.json()[0]["risk_level"] == "MEDIUM"

    # 2. Add a note
    note_payload = {"note_content": "Patient is responding well to treatment."}
    note_resp = client.post(f"/clinicians/me/patients/{patient_id}/notes", json=note_payload, headers=headers)
    assert note_resp.status_code == 200, f"Failed to add note: {note_resp.text}"
    assert note_resp.json()[0]["note_content"] == note_payload["note_content"]
    assert note_resp.json()[0]["patient_id"] == patient_id

    # 3. Get thresholds
    thresholds_resp = client.get(f"/clinicians/me/patients/{patient_id}/thresholds", headers=headers)
    assert thresholds_resp.status_code == 200
    assert isinstance(thresholds_resp.json(), list)

    # 4. Set/Update thresholds
    threshold_payload = [
        {"data_type": "GLUCOSE", "min_value": 65.0, "max_value": 175.0},
        {"data_type": "BMI", "min_value": 19.0, "max_value": 25.0}
    ]
    set_thresholds_resp = client.put(f"/clinicians/me/patients/{patient_id}/thresholds", json=threshold_payload, headers=headers)
    assert set_thresholds_resp.status_code == 200, f"Failed to set thresholds: {set_thresholds_resp.text}"
    updated_thresholds = set_thresholds_resp.json()
    assert len(updated_thresholds) >= 2
    glucose_threshold = next((t for t in updated_thresholds if t["data_type"] == "GLUCOSE"), None)
    assert glucose_threshold is not None
    assert glucose_threshold["min_value"] == 65.0
