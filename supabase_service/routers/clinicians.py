import logging
import asyncio
from fastapi import APIRouter, Depends, HTTPException, Header, Query
from pydantic import BaseModel, Field
from typing import List, Optional
from supabase_auth.errors import AuthApiError
from postgrest.exceptions import APIError
from enum import Enum
from datetime import date, datetime, timedelta
from gotrue.types import User

from ..client import supabase
from ..core.dependencies import get_current_user
from ..core.utils import calculate_age, create_paginated_response

# --- Helper Functions / Dependencies ---

async def verify_patient_assignment(patient_id: int, clinician_id: int):
    """
    Verifies that a patient is assigned to the specified clinician.
    Raises HTTPException 404 if not found or not assigned.
    """
    try:
        await supabase.table('patient_profiles').select('id').eq('id', patient_id).eq('clinician_id', clinician_id).single().execute()
    except APIError as e:
        if e.code == "PGRST116": # Not found
            raise HTTPException(status_code=404, detail="Patient not found or not assigned to this clinician.")
        raise HTTPException(status_code=500, detail=f"Database error verifying patient assignment: {e.message}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")


async def get_current_clinician_profile(user: User = Depends(get_current_user)):
    """
    Dependency to get the current user, verify they are a clinician,
    and return their full profile from the `clinician_profiles` table.
    """
    try:
        # Fetch the clinician profile using the user's ID. This serves as the role check.
        profile_response = await supabase.table('clinician_profiles').select('*').eq('user_id', user.id).single().execute()
        
        return profile_response.data
    except APIError as e:
        if e.code == "PGRST116": # "JSON object requested, but 0 rows returned"
            raise HTTPException(status_code=403, detail="Access denied: User is not a clinician.")
        raise HTTPException(status_code=500, detail=f"Database error: {e.message}")
    except Exception as e:
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
        
        patients_response = await query.execute()

        return create_paginated_response(
            query_response_data=patients_response.data,
            query_response_count=patients_response.count,
            page=page,
            page_size=page_size
        )
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
        # 1. Verify patient is assigned to the current clinician
        await verify_patient_assignment(patient_id, clinician_profile['id'])

        # 2. Fetch patient profile
        profile_res = await supabase.table('patient_profiles').select('*').eq('id', patient_id).single().execute()
        profile = profile_res.data
        profile['age'] = calculate_age(profile.get("date_of_birth"))

        # 3. Define pagination ranges
        monitor_from = (monitor_page - 1) * monitor_page_size
        monitor_to = monitor_from + monitor_page_size - 1
        logs_from = (logs_page - 1) * logs_page_size
        logs_to = logs_from + logs_page_size - 1
        notes_from = (notes_page - 1) * notes_page_size
        notes_to = notes_from + notes_page_size - 1

        # 4. Concurrently fetch all related data
        monitor_task = supabase.table('patient_monitor_data').select('*', count='exact').eq('patient_id', patient_id).order('measured_at', desc=True).range(monitor_from, monitor_to).execute()
        logs_task = supabase.table('daily_patient_logs').select('*', count='exact').eq('patient_id', patient_id).order('log_date', desc=True).range(logs_from, logs_to).execute()
        notes_task = supabase.table('clinician_notes').select('*', count='exact').eq('patient_id', patient_id).order('created_at', desc=True).range(notes_from, notes_to).execute()
        thresholds_task = supabase.table('patient_thresholds').select('*').eq('patient_id', patient_id).execute()

        monitor_res, logs_res, notes_res, thresholds_res = await asyncio.gather(
            monitor_task, logs_task, notes_task, thresholds_task
        )

        # 5. Assemble the response
        return {
            "profile": profile,
            "monitor_data": create_paginated_response(
                query_response_data=monitor_res.data,
                query_response_count=monitor_res.count,
                page=monitor_page,
                page_size=monitor_page_size
            ),
            "daily_logs": create_paginated_response(
                query_response_data=logs_res.data,
                query_response_count=logs_res.count,
                page=logs_page,
                page_size=logs_page_size
            ),
            "notes": create_paginated_response(
                query_response_data=notes_res.data,
                query_response_count=notes_res.count,
                page=notes_page,
                page_size=notes_page_size
            ),
            "thresholds": thresholds_res.data
        }
    except APIError as e:
        if e.code == "PGRST116": # "JSON object requested, but 0 rows returned"
             # This should ideally not be reached if verify_patient_assignment passed,
             # but could happen in a race condition (e.g., patient deleted after check).
             raise HTTPException(status_code=404, detail="Patient not found.")
        raise HTTPException(status_code=500, detail=f"Database error: {e.message}")
    except Exception as e:
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
        updated_patient_res = await supabase.table('patient_profiles').update(update_payload).eq('id', patient_id).eq('clinician_id', clinician_profile['id']).execute()
        
        if not updated_patient_res.data:
            raise HTTPException(status_code=404, detail="Patient not found or not assigned to this clinician.")

        return updated_patient_res.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update patient risk level: {str(e)}")

@router.post("/me/patients/{patient_id}/notes", summary="Add a new note for an assigned patient only")
async def add_patient_note(patient_id: int, note_data: ClinicianNoteCreate, clinician_profile: dict = Depends(get_current_clinician_profile)):
    """
    Adds a clinical note to a patient, but only if they are assigned to the clinician.
    """
    try:
        # 1. Verify patient is assigned to the current clinician
        await verify_patient_assignment(patient_id, clinician_profile['id'])

        # 2. Insert the note
        insert_payload = {
            "patient_id": patient_id,
            "clinician_id": clinician_profile['id'],
            "clinician_name_snapshot": clinician_profile.get('name'),
            "note_content": note_data.note_content
        }
        new_note_res = await supabase.table('clinician_notes').insert(insert_payload).execute()
        
        if not new_note_res.data:
             # This can happen if RLS `WITH CHECK` fails, but PostgREST often returns a more specific error.
             # We'll treat it as a generic failure to find/access the resource.
            raise HTTPException(status_code=403, detail="Could not add note. This may be due to a permissions issue.")

        return new_note_res.data[0]
    except APIError as e:
        # RLS check failure on insert/update often results in a 403 or 404 from PostgREST
        if e.code == "42501": # permission_denied
            raise HTTPException(status_code=403, detail="Access denied: You do not have permission to add a note for this patient.")
        raise HTTPException(status_code=500, detail=f"Database error while adding note: {e.message}")
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add note: {str(e)}")

@router.get("/me/patients/{patient_id}/thresholds", summary="Get thresholds for an assigned patient")
async def get_patient_thresholds(patient_id: int, clinician_profile: dict = Depends(get_current_clinician_profile)):
    """
    Retrieves health thresholds for a patient, but only if they are assigned to the clinician.
    """
    try:
        # 1. Verify patient is assigned to the current clinician
        await verify_patient_assignment(patient_id, clinician_profile['id'])

        # 2. Fetch the thresholds
        thresholds = await supabase.table('patient_thresholds').select('*').eq('patient_id', patient_id).execute()
        return thresholds.data
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get thresholds: {str(e)}")

@router.put("/me/patients/{patient_id}/thresholds", summary="Set/Update thresholds for an assigned patient")
async def set_patient_thresholds(patient_id: int, thresholds: List[PatientThresholdUpdate], clinician_profile: dict = Depends(get_current_clinician_profile)):
    """
    Sets or updates multiple health thresholds for a patient, but only if they are assigned to the clinician.
    This uses an 'upsert' operation to either create new thresholds or update existing ones.
    """
    try:
        # 1. Verify patient is assigned to the current clinician
        await verify_patient_assignment(patient_id, clinician_profile['id'])

        # 2. Prepare and execute the upsert
        upsert_payload = [
            {
                "patient_id": patient_id,
                "data_type": t.data_type,
                "min_value": t.min_value,
                "max_value": t.max_value
            } for t in thresholds
        ]
        
        updated_thresholds_res = await supabase.table('patient_thresholds').upsert(upsert_payload).execute()
        
        if not updated_thresholds_res.data:
            raise HTTPException(status_code=403, detail="Could not set thresholds. This may be due to a permissions issue.")

        return updated_thresholds_res.data
    except APIError as e:
        if e.code == "42501": # permission_denied
            raise HTTPException(status_code=403, detail="Access denied: You do not have permission to set thresholds for this patient.")
        raise HTTPException(status_code=500, detail=f"Database error while setting thresholds: {e.message}")
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
        await supabase.table('patient_profiles').update({"clinician_id": None}).eq('clinician_id', clinician_id).execute()

        # Step 2: Preserve notes by detaching them from the clinician.
        await supabase.table('clinician_notes').update({
            "clinician_id": None,
            "clinician_name_snapshot": clinician_name
        }).eq('clinician_id', clinician_id).execute()

        # Step 3: Delete the associated auth user.
        # The 'ON DELETE CASCADE' on the 'clinician_profiles' table will automatically delete the profile.
        if user_id:
            try:
                await supabase.auth.admin.delete_user(user_id)
            except Exception as auth_error:
                # If auth user deletion fails, the profile remains, which is safe.
                raise HTTPException(
                    status_code=500,
                    detail=f"Failed to delete auth user {user_id}. Aborting deletion. Error: {str(auth_error)}"
                )

        return {"message": f"Clinician profile for user {user_id} and associated auth user deleted successfully."}
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete own clinician profile: {str(e)}")
