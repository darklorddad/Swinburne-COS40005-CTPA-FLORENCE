import logging
import math
from fastapi import APIRouter, Depends, HTTPException, Header, Query
from pydantic import BaseModel, Field
from typing import List, Optional
from supabase_auth.errors import AuthApiError
from enum import Enum
from datetime import date, datetime, timedelta

from ..client import supabase

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

class PatientBasicInfo(BaseModel):
    id: int
    name: Optional[str] = None
    phone_number: Optional[str] = None
    risk_level: str

class PaginatedAssignedPatientsResponse(BaseModel):
    total_items: int
    total_pages: int
    current_page: int
    page_size: int
    data: List[PatientBasicInfo]

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

@router.get("/me/patients", summary="Get a list of all patients assigned to me", response_model=PaginatedAssignedPatientsResponse)
async def get_assigned_patients(
    clinician_profile: dict = Depends(get_current_clinician_profile),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
):
    """Retrieves a paginated list of all patients assigned to the currently authenticated clinician."""
    try:
        from_row = (page - 1) * page_size
        to_row = from_row + page_size - 1

        query = supabase.table('patient_profiles').select(
            'id, name, phone_number, risk_level',
            count='exact'
        ).eq('clinician_id', clinician_profile['id']).order('name').range(from_row, to_row)
        
        patients_response = query.execute()

        total_items = patients_response.count if patients_response.count is not None else 0
        total_pages = math.ceil(total_items / page_size) if total_items > 0 else 0

        return {
            "total_items": total_items,
            "total_pages": total_pages,
            "current_page": page,
            "page_size": page_size,
            "data": patients_response.data
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve assigned patients: {str(e)}")

@router.get("/me/patients/{patient_id}", summary="Get full profile & data for an assigned patient only")
async def get_assigned_patient_details(
    patient_id: int,
    clinician_profile: dict = Depends(get_current_clinician_profile),
    # Pagination for related data
    monitor_page: int = Query(1, ge=1),
    monitor_page_size: int = Query(50, ge=1, le=100),
    logs_page: int = Query(1, ge=1),
    logs_page_size: int = Query(50, ge=1, le=100),
    notes_page: int = Query(1, ge=1),
    notes_page_size: int = Query(20, ge=1, le=50),
):
    """
    Retrieves the full profile and paginated related data for a single patient,
    but only if they are assigned to the currently authenticated clinician.
    """
    try:
        # 1. Fetch patient profile and verify assignment
        profile_res = supabase.table('patient_profiles').select('*').eq('id', patient_id).eq('clinician_id', clinician_profile['id']).single().execute()
        profile = profile_res.data

        # Calculate age
        dob_str = profile.get("date_of_birth")
        if dob_str:
            try:
                dob = date.fromisoformat(dob_str)
                today = date.today()
                profile['age'] = today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))
            except (ValueError, TypeError):
                profile['age'] = None
        else:
            profile['age'] = None

        # 2. Fetch paginated monitor data
        monitor_from = (monitor_page - 1) * monitor_page_size
        monitor_to = monitor_from + monitor_page_size - 1
        monitor_res = supabase.table('patient_monitor_data').select('*', count='exact').eq('patient_id', patient_id).order('measured_at', desc=True).range(monitor_from, monitor_to).execute()
        
        # 3. Fetch paginated daily logs
        logs_from = (logs_page - 1) * logs_page_size
        logs_to = logs_from + logs_page_size - 1
        logs_res = supabase.table('daily_patient_logs').select('*', count='exact').eq('patient_id', patient_id).order('log_date', desc=True).range(logs_from, logs_to).execute()

        # 4. Fetch paginated clinician notes
        notes_from = (notes_page - 1) * notes_page_size
        notes_to = notes_from + notes_page_size - 1
        notes_res = supabase.table('clinician_notes').select('*', count='exact').eq('patient_id', patient_id).order('created_at', desc=True).range(notes_from, notes_to).execute()

        # 5. Fetch all thresholds (not paginated)
        thresholds_res = supabase.table('patient_thresholds').select('*').eq('patient_id', patient_id).execute()

        return {
            "profile": profile,
            "monitor_data": {
                "data": monitor_res.data,
                "total_items": monitor_res.count,
                "current_page": monitor_page,
                "page_size": monitor_page_size,
                "total_pages": math.ceil(monitor_res.count / monitor_page_size) if monitor_res.count else 0
            },
            "daily_logs": {
                "data": logs_res.data,
                "total_items": logs_res.count,
                "current_page": logs_page,
                "page_size": logs_page_size,
                "total_pages": math.ceil(logs_res.count / logs_page_size) if logs_res.count else 0
            },
            "notes": {
                "data": notes_res.data,
                "total_items": notes_res.count,
                "current_page": notes_page,
                "page_size": notes_page_size,
                "total_pages": math.ceil(notes_res.count / notes_page_size) if notes_res.count else 0
            },
            "thresholds": thresholds_res.data
        }
    except Exception as e:
        if "Expected 1 row, got 0" in str(e):
             raise HTTPException(status_code=404, detail="Patient not found or not assigned to this clinician.")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve patient details: {str(e)}")

@router.put("/me/patients/{patient_id}/assess-risk", summary="Update the risk level for an assigned patient only")
async def assess_patient_risk(patient_id: int, risk_data: RiskAssessmentUpdate, clinician_profile: dict = Depends(get_current_clinician_profile)):
    """Updates the risk level for a patient assigned to the clinician."""
    try:
        update_payload = {
            "risk_level": risk_data.risk_level.value,
            "last_risk_assessment": "now()"
        }
        # Atomically update only if the patient is assigned to the current clinician.
        updated_patient_res = supabase.table('patient_profiles').update(update_payload).eq('id', patient_id).eq('clinician_id', clinician_profile['id']).execute()
        
        if not updated_patient_res.data:
            raise HTTPException(status_code=404, detail="Patient not found or not assigned to this clinician.")

        return updated_patient_res.data[0]
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
            "clinician_name_snapshot": clinician_profile.get('name'),
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


@router.delete("/me", summary="Delete my own clinician profile")
async def delete_own_clinician_profile(clinician_profile: dict = Depends(get_current_clinician_profile)):
    """
    Deletes the currently authenticated clinician's profile, unassigns their patients,
    preserves their notes, and deletes the corresponding user from Supabase Auth.
    """
    try:
        clinician_id = clinician_profile.get("id")
        user_id = clinician_profile.get("user_id")
        clinician_name = clinician_profile.get("name")

        # Step 1: Unassign all patients from this clinician.
        supabase.table('patient_profiles').update({"clinician_id": None}).eq('clinician_id', clinician_id).execute()

        # Step 2: Preserve notes by detaching them from the clinician.
        supabase.table('clinician_notes').update({
            "clinician_id": None,
            "clinician_name_snapshot": clinician_name
        }).eq('clinician_id', clinician_id).execute()

        # Step 3: Delete the associated auth user first to prevent orphaned users.
        if user_id:
            try:
                supabase.auth.admin.delete_user(user_id)
            except Exception as auth_error:
                raise HTTPException(
                    status_code=500,
                    detail=f"Failed to delete auth user {user_id}. Aborting deletion. Error: {str(auth_error)}"
                )

        # Step 4: Delete the clinician's profile.
        deleted_profile_response = supabase.table('clinician_profiles').delete().eq('id', clinician_id).execute()
        
        if not deleted_profile_response.data:
            logging.critical(f"CRITICAL: Auth user {user_id} was deleted, but failed to delete clinician profile {clinician_id}. Manual cleanup required.")
            raise HTTPException(status_code=500, detail=f"Auth user deleted, but failed to delete clinician profile {clinician_id}.")

        return {"message": f"Clinician profile with id {clinician_id} and associated auth user deleted successfully."}
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete own clinician profile: {str(e)}")
