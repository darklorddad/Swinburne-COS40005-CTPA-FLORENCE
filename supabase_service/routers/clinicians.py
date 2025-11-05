import logging
import asyncio
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from typing import List, Optional
from postgrest.exceptions import APIError
from supabase.lib.client_async import AsyncClient

from ..client import supabase_admin_client
from ..core.dependencies import get_user_supabase_client
from ..core.utils import calculate_age, create_paginated_response
from ..models import RiskLevel

# --- Helper Functions / Dependencies ---

async def get_current_clinician_profile(supabase: AsyncClient = Depends(get_user_supabase_client)):
    """
    Dependency to get the current user's clinician profile.
    RLS ensures this only succeeds if the user is a clinician.
    """
    try:
        # RLS is active, so this select will only work if the user is a clinician.
        profile_response = await supabase.table('clinician_profiles').select('*').single().execute()
        return profile_response.data
    except APIError as e:
        if e.code == "PGRST116": # "JSON object requested, but 0 rows returned"
            raise HTTPException(status_code=403, detail="Access denied: User is not a clinician or profile not found.")
        logging.error(f"Database error fetching clinician profile: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")
    except Exception as e:
        logging.error(f"Unexpected error fetching clinician profile: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")

# --- Pydantic Models ---

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
    supabase: AsyncClient = Depends(get_user_supabase_client),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
):
    """
    Retrieves a paginated list of all patients assigned to the currently authenticated clinician.
    RLS policies ensure that only assigned patients are returned.
    """
    try:
        from_row = (page - 1) * page_size
        to_row = from_row + page_size - 1

        # RLS on 'patient_profiles' restricts this query to only patients assigned to the current clinician.
        query = supabase.table('patient_profiles').select(
            'id, name, phone_number, risk_level',
            count='exact'
        ).order('name').range(from_row, to_row)
        
        patients_response = await query.execute()

        return create_paginated_response(
            query_response_data=patients_response.data,
            query_response_count=patients_response.count,
            page=page,
            page_size=page_size
        )
    except Exception as e:
        logging.error(f"Failed to retrieve assigned patients: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")

@router.get("/me/patients/{patient_id}", summary="Get full profile & data for an assigned patient only")
async def get_assigned_patient_details(
    patient_id: int,
    supabase: AsyncClient = Depends(get_user_supabase_client),
    # Pagination for related data
    monitor_page: int = Query(1, ge=1),
    monitor_page_size: int = Query(50, ge=1, le=100),
    logs_page: int = Query(1, ge=1),
    logs_page_size: int = Query(50, ge=1, le=100),
    notes_page: int = Query(1, ge=1),
    notes_page_size: int = Query(20, ge=1, le=50),
):
    """
    Retrieves the full profile and paginated related data for a single patient.
    RLS ensures this is only possible for patients assigned to the authenticated clinician.
    """
    try:
        # RLS on 'patient_profiles' will enforce that the clinician can only fetch
        # profiles of patients assigned to them. If not assigned, this will fail.
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

        # 4. Concurrently fetch all related data. RLS is applied to each of these queries.
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
             # This now correctly indicates that the patient was not found OR not assigned to the clinician.
             raise HTTPException(status_code=404, detail="Patient not found or not assigned to this clinician.")
        logging.error(f"Database error retrieving patient details: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")
    except Exception as e:
        logging.error(f"Failed to retrieve patient details: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")

@router.put("/me/patients/{patient_id}/assess-risk", summary="Update the risk level for an assigned patient only")
async def assess_patient_risk(patient_id: int, risk_data: RiskAssessmentUpdate, supabase: AsyncClient = Depends(get_user_supabase_client)):
    """
    Updates the risk level for an assigned patient. RLS ensures this is only
    possible for patients assigned to the clinician.
    """
    try:
        update_payload = {
            "risk_level": risk_data.risk_level.value,
            "last_risk_assessment": "now()"
        }
        # RLS on 'patient_profiles' for UPDATE handles the authorization check.
        updated_patient_res = await supabase.table('patient_profiles').update(update_payload).eq('id', patient_id).execute()
        
        if not updated_patient_res.data:
            raise HTTPException(status_code=404, detail="Patient not found or not assigned to this clinician.")

        return updated_patient_res.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        logging.error(f"Failed to update patient risk level: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")

@router.post("/me/patients/{patient_id}/notes", summary="Add a new note for an assigned patient only")
async def add_patient_note(
    patient_id: int, 
    note_data: ClinicianNoteCreate, 
    clinician_profile: dict = Depends(get_current_clinician_profile),
    supabase: AsyncClient = Depends(get_user_supabase_client)
):
    """
    Adds a clinical note to a patient. RLS ensures this is only possible for
    patients assigned to the clinician.
    """
    try:
        insert_payload = {
            "patient_id": patient_id,
            "clinician_id": clinician_profile['id'],
            "clinician_name_snapshot": clinician_profile.get('name'),
            "note_content": note_data.note_content
        }
        # RLS policy on 'clinician_notes' for INSERT handles the authorization check.
        new_note_res = await supabase.table('clinician_notes').insert(insert_payload).execute()
        
        if not new_note_res.data:
            raise HTTPException(status_code=403, detail="Could not add note. Patient may not be assigned to you or does not exist.")

        return new_note_res.data[0]
    except APIError as e:
        if e.code == "42501": # permission_denied
            raise HTTPException(status_code=403, detail="Access denied: You do not have permission to add a note for this patient.")
        logging.error(f"Database error while adding note: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")
    except HTTPException as e:
        raise e
    except Exception as e:
        logging.error(f"Failed to add note: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")

@router.get("/me/patients/{patient_id}/thresholds", summary="Get thresholds for an assigned patient")
async def get_patient_thresholds(patient_id: int, supabase: AsyncClient = Depends(get_user_supabase_client)):
    """
    Retrieves health thresholds for a patient. RLS ensures this is only possible
    for patients assigned to the clinician.
    """
    try:
        # RLS on 'patient_thresholds' for SELECT handles the authorization check.
        thresholds_res = await supabase.table('patient_thresholds').select('*').eq('patient_id', patient_id).execute()
        
        # An empty list is a valid response if no thresholds are set, so we don't check for 404.
        # RLS will have already prevented access if the patient isn't assigned.
        return thresholds_res.data
    except HTTPException as e:
        raise e
    except Exception as e:
        logging.error(f"Failed to get thresholds: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")

@router.put("/me/patients/{patient_id}/thresholds", summary="Set/Update thresholds for an assigned patient")
async def set_patient_thresholds(patient_id: int, thresholds: List[PatientThresholdUpdate], supabase: AsyncClient = Depends(get_user_supabase_client)):
    """
    Sets or updates multiple health thresholds for an assigned patient.
    RLS ensures this is only possible for patients assigned to the clinician.
    """
    try:
        # RLS on 'patient_thresholds' for INSERT/UPDATE handles the authorization check.
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
            raise HTTPException(status_code=403, detail="Could not set thresholds. Patient may not be assigned to you or does not exist.")

        return updated_thresholds_res.data
    except APIError as e:
        if e.code == "42501": # permission_denied
            raise HTTPException(status_code=403, detail="Access denied: You do not have permission to set thresholds for this patient.")
        logging.error(f"Database error while setting thresholds: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")
    except HTTPException as e:
        raise e
    except Exception as e:
        logging.error(f"Failed to set thresholds: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")


@router.delete("/me", summary="Delete my own clinician profile")
async def delete_own_clinician_profile(clinician_profile: dict = Depends(get_current_clinician_profile)):
    """
    Deletes the currently authenticated clinician's profile and associated auth user.
    This is an atomic operation handled by a database function.
    This requires an admin client to call the RPC as a security definer.
    """
    try:
        clinician_id = clinician_profile.get("id")
        user_id = clinician_profile.get("user_id")

        # Call the database function using the admin client.
        await supabase_admin_client.rpc('delete_clinician_and_clean_up', {'p_clinician_id': clinician_id}).execute()

        return {"message": f"Clinician profile for user {user_id} and associated auth user deleted successfully."}
    except APIError as e:
        # The RPC function might raise an exception.
        logging.error(f"Database error during clinician deletion: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")
    except Exception as e:
        logging.error(f"Failed to delete own clinician profile: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")
