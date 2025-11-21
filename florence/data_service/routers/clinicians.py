from fastapi import APIRouter, Depends, HTTPException, Header
from pydantic import BaseModel, Field
from typing import List, Optional
from supabase_auth.errors import AuthApiError
from enum import Enum

from client import supabase

# --- Helper Functions / Dependencies ---

async def get_current_clinician_profile(authorization: str = Header(...)):
    """
    Dependency to get the current user, verify they are a clinician,
    and return their full profile from the `clinician_profiles` table.
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authentication scheme.")
    
    token = authorization.split(" ")[1]
    
    try:
        user_response = supabase.auth.get_user(token)
        user = user_response.user
        if not user:
            raise HTTPException(status_code=401, detail="Invalid token.")
        
        # Fetch the clinician profile using the user's ID. This serves as the role check.
        profile_response = supabase.table('clinician_profiles').select('*').eq('user_id', user.id).single().execute()
        
        return profile_response.data
    except AuthApiError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e.message}")
    except Exception as e:
        if "Expected 1 row, got 0" in str(e):
            raise HTTPException(status_code=403, detail="Access denied: User is not a clinician.")
        raise HTTPException(status_code=500, detail=str(e))

# --- Pydantic Models ---

class RiskLevel(str, Enum):
    LOW = 'LOW'
    MEDIUM = 'MEDIUM'
    HIGH = 'HIGH'

class RiskAssessmentUpdate(BaseModel):
    risk_level: RiskLevel

class ClinicianNoteCreate(BaseModel):
    note_content: str = Field(..., min_length=1)

class PatientThresholdUpdate(BaseModel):
    data_type: str
    min_value: float
    max_value: float

# --- Router Definition ---

router = APIRouter(
    prefix="/clinicians",
    tags=["Clinician (Management)"]
)

# --- Endpoints ---

@router.get("/me", summary="Get my own clinician profile")
async def get_own_clinician_profile(clinician_profile: dict = Depends(get_current_clinician_profile)):
    """Retrieves the complete profile for the currently authenticated clinician."""
    return clinician_profile

@router.get("/me/patients", summary="Get a list of all patients assigned to me")
async def get_assigned_patients(clinician_profile: dict = Depends(get_current_clinician_profile)):
    """Retrieves a list of all patients assigned to the currently authenticated clinician."""
    try:
        patients_response = supabase.table('patient_profiles').select('id, name, phone_number, risk_level').eq('clinician_id', clinician_profile['id']).execute()
        return patients_response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve assigned patients: {str(e)}")

@router.get("/me/patients/{patient_id}", summary="Get full profile & data for an assigned patient only")
async def get_assigned_patient_details(patient_id: int, clinician_profile: dict = Depends(get_current_clinician_profile)):
    """
    Retrieves the full profile and all related data for a single patient,
    but only if they are assigned to the currently authenticated clinician.
    """
    try:
        # Verify patient is assigned to this clinician
        patient_profile_res = supabase.table('patient_profiles').select('*', count='exact').eq('id', patient_id).eq('clinician_id', clinician_profile['id']).single().execute()
        
        patient_profile = patient_profile_res.data

        # Fetch related data
        monitor_data = supabase.table('patient_monitor_data').select('*').eq('patient_id', patient_id).execute().data
        daily_logs = supabase.table('daily_patient_logs').select('*').eq('patient_id', patient_id).execute().data
        thresholds = supabase.table('patient_thresholds').select('*').eq('patient_id', patient_id).execute().data
        notes = supabase.table('clinician_notes').select('*').eq('patient_id', patient_id).execute().data
        
        # ADD THIS LINE to fetch activity
        activity_logs = supabase.table('patient_activity_logs').select('*').eq('patient_id', patient_id).order('performed_at', desc=True).execute().data

        return {
            "profile": patient_profile,
            "monitor_data": monitor_data,
            "daily_logs": daily_logs,
            "thresholds": thresholds,
            "notes": notes,
            "activity_logs": activity_logs # Add this
        }
    except Exception as e:
        if "Expected 1 row, got 0" in str(e):
             raise HTTPException(status_code=404, detail="Patient not found or not assigned to this clinician.")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve patient details: {str(e)}")

@router.put("/me/patients/{patient_id}/assess-risk", summary="Update the risk level for an assigned patient only")
async def assess_patient_risk(patient_id: int, risk_data: RiskAssessmentUpdate, clinician_profile: dict = Depends(get_current_clinician_profile)):
    """Updates the risk level for a patient assigned to the clinician."""
    try:
        # Verify patient is assigned
        patient_check = supabase.table('patient_profiles').select('id', count='exact').eq('id', patient_id).eq('clinician_id', clinician_profile['id']).execute()
        if patient_check.count == 0:
            raise HTTPException(status_code=404, detail="Patient not found or not assigned to this clinician.")

        update_payload = {
            "risk_level": risk_data.risk_level.value,
            "last_risk_assessment": "now()"
        }
        updated_patient = supabase.table('patient_profiles').update(update_payload).eq('id', patient_id).execute()
        
        return updated_patient.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update patient risk level: {str(e)}")

@router.post("/me/patients/{patient_id}/notes", summary="Add a new note for an assigned patient only")
async def add_patient_note(patient_id: int, note_data: ClinicianNoteCreate, clinician_profile: dict = Depends(get_current_clinician_profile)):
    """Adds a clinical note to a patient assigned to the clinician."""
    try:
        # Verify patient is assigned
        patient_check = supabase.table('patient_profiles').select('id', count='exact').eq('id', patient_id).eq('clinician_id', clinician_profile['id']).execute()
        if patient_check.count == 0:
            raise HTTPException(status_code=404, detail="Patient not found or not assigned to this clinician.")

        insert_payload = {
            "patient_id": patient_id,
            "clinician_id": clinician_profile['id'],
            "note_content": note_data.note_content
        }
        new_note = supabase.table('clinician_notes').insert(insert_payload).execute()
        
        return new_note.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add note: {str(e)}")

@router.get("/me/patients/{patient_id}/thresholds", summary="Get thresholds for an assigned patient")
async def get_patient_thresholds(patient_id: int, clinician_profile: dict = Depends(get_current_clinician_profile)):
    """Retrieves health thresholds for a patient assigned to the clinician."""
    try:
        # Verify patient is assigned
        patient_check = supabase.table('patient_profiles').select('id', count='exact').eq('id', patient_id).eq('clinician_id', clinician_profile['id']).execute()
        if patient_check.count == 0:
            raise HTTPException(status_code=404, detail="Patient not found or not assigned to this clinician.")

        thresholds = supabase.table('patient_thresholds').select('*').eq('patient_id', patient_id).execute()
        return thresholds.data
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get thresholds: {str(e)}")

@router.put("/me/patients/{patient_id}/thresholds", summary="Set/Update thresholds for an assigned patient")
async def set_patient_thresholds(patient_id: int, thresholds: List[PatientThresholdUpdate], clinician_profile: dict = Depends(get_current_clinician_profile)):
    """
    Sets or updates multiple health thresholds for an assigned patient.
    This uses an 'upsert' operation to either create new thresholds or update existing ones.
    """
    try:
        # Verify patient is assigned
        patient_check = supabase.table('patient_profiles').select('id', count='exact').eq('id', patient_id).eq('clinician_id', clinician_profile['id']).execute()
        if patient_check.count == 0:
            raise HTTPException(status_code=404, detail="Patient not found or not assigned to this clinician.")

        upsert_payload = [
            {
                "patient_id": patient_id,
                "data_type": t.data_type,
                "min_value": t.min_value,
                "max_value": t.max_value
            } for t in thresholds
        ]
        
        updated_thresholds = supabase.table('patient_thresholds').upsert(upsert_payload).execute()
        
        return updated_thresholds.data
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to set thresholds: {str(e)}")
