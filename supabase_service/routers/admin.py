import logging
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, model_validator, EmailStr
from typing import Optional, List
from enum import Enum
from datetime import date, datetime
from supabase_auth.errors import AuthApiError
from postgrest.exceptions import APIError
import traceback

from ..client import supabase
from .authentication import get_current_admin_user
from ..core.constants import DEFAULT_THRESHOLDS
from ..models import MonitorDataType
from ..core.utils import calculate_age, create_paginated_response, ensure_not_empty

# --- Pydantic Models ---

class RiskLevel(str, Enum):
    LOW = 'LOW'
    MEDIUM = 'MEDIUM'
    HIGH = 'HIGH'

class PatientAdminCreate(BaseModel):
    email: EmailStr
    password: str
    name: str
    phone_number: Optional[str] = None
    gender: Optional[str] = None
    date_of_birth: Optional[date] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_relationship: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    risk_level: Optional[RiskLevel] = RiskLevel.LOW
    organisation_id: Optional[int] = None
    clinician_id: Optional[int] = None

class PatientProfileAdminUpdate(BaseModel):
    """Fields an admin is allowed to update on a patient's profile."""
    name: Optional[str] = None
    phone_number: Optional[str] = None
    gender: Optional[str] = None
    date_of_birth: Optional[date] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_relationship: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    risk_level: Optional[RiskLevel] = None
    organisation_id: Optional[int] = None
    clinician_id: Optional[int] = None

class ClinicianAdminCreate(BaseModel):
    email: EmailStr
    password: str
    name: str
    phone_number: Optional[str] = None
    gender: Optional[str] = None
    organisation_id: int

class ClinicianProfileAdminUpdate(BaseModel):
    """Fields an admin is allowed to update on a clinician's profile."""
    name: Optional[str] = None
    phone_number: Optional[str] = None
    gender: Optional[str] = None
    organisation_id: Optional[int] = None

class OrganisationAdminUpdate(BaseModel):
    """Fields an admin is allowed to update on an organisation."""
    name: Optional[str] = None

class OrganisationAdminCreate(BaseModel):
    """Fields for creating a new organisation."""
    name: str

# --- New Pydantic Models for Admin Updates ---

class MealTime(str, Enum):
    BREAKFAST = 'BREAKFAST'
    LUNCH = 'LUNCH'
    DINNER = 'DINNER'

class DailyLogAdminCreate(BaseModel):
    patient_id: int
    log_date: date
    meal_time: MealTime
    glucose_before_meal: Optional[float] = None
    glucose_after_meal: Optional[float] = None
    meal_desc: Optional[str] = None

    @model_validator(mode='before')
    @classmethod
    def check_at_least_one_glucose_reading(cls, values):
        before, after = values.get('glucose_before_meal'), values.get('glucose_after_meal')
        if before is None and after is None:
            raise ValueError('At least one of glucose_before_meal or glucose_after_meal must be provided.')
        return values

class DailyLogAdminUpdate(BaseModel):
    log_date: Optional[date] = None
    meal_time: Optional[MealTime] = None
    glucose_before_meal: Optional[float] = None
    glucose_after_meal: Optional[float] = None
    meal_desc: Optional[str] = None

class MonitorDataAdminCreate(BaseModel):
    patient_id: int
    data_type: MonitorDataType
    value: float
    measured_at: datetime

class MonitorDataAdminUpdate(BaseModel):
    data_type: Optional[MonitorDataType] = None
    value: Optional[float] = None
    measured_at: Optional[datetime] = None

class PatientThresholdAdminUpdate(BaseModel):
    data_type: Optional[MonitorDataType] = None
    min_value: Optional[float] = None
    max_value: Optional[float] = None

class ClinicianNoteAdminUpdate(BaseModel):
    note_content: Optional[str] = None


# --- Pydantic Models for Paginated Admin Views ---

class PatientProfileAdminView(BaseModel):
    id: int
    user_id: str # It's a UUID but comes as string
    name: Optional[str] = None
    phone_number: Optional[str] = None
    gender: Optional[str] = None
    date_of_birth: Optional[date] = None
    organisation_id: Optional[int] = None
    clinician_id: Optional[int] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_relationship: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    risk_level: str
    last_risk_assessment: Optional[datetime] = None
    organisations: Optional[dict] = None # e.g. {'name': 'Org Name'}
    clinician_profiles: Optional[dict] = None # e.g. {'name': 'Clinician Name'}
    age: Optional[int] = None

class PaginatedPatientsResponse(BaseModel):
    total_items: int
    total_pages: int
    current_page: int
    page_size: int
    data: List[PatientProfileAdminView]

class ClinicianProfileAdminView(BaseModel):
    id: int
    user_id: str
    name: Optional[str] = None
    phone_number: Optional[str] = None
    gender: Optional[str] = None
    organisation_id: int
    organisations: Optional[dict] = None
    assigned_patients: List[str]

class PaginatedCliniciansResponse(BaseModel):
    total_items: int
    total_pages: int
    current_page: int
    page_size: int
    data: List[ClinicianProfileAdminView]

class OrganisationView(BaseModel):
    id: int
    name: str

class PaginatedOrganisationsResponse(BaseModel):
    total_items: int
    total_pages: int
    current_page: int
    page_size: int
    data: List[OrganisationView]

class DailyLogAdminView(BaseModel):
    id: int
    patient_id: int
    log_date: date
    meal_time: MealTime
    glucose_before_meal: Optional[float] = None
    glucose_after_meal: Optional[float] = None
    meal_desc: Optional[str] = None
    patient_profiles: Optional[dict] = None # e.g. {'name': 'Patient Name'}

class PaginatedDailyLogsResponse(BaseModel):
    total_items: int
    total_pages: int
    current_page: int
    page_size: int
    data: List[DailyLogAdminView]

class MonitorDataAdminView(BaseModel):
    id: int
    patient_id: int
    data_type: str
    value: float
    measured_at: datetime
    patient_profiles: Optional[dict] = None
    unit: str

class PaginatedMonitorDataResponse(BaseModel):
    total_items: int
    total_pages: int
    current_page: int
    page_size: int
    data: List[MonitorDataAdminView]

class PatientThresholdAdminView(BaseModel):
    id: int
    patient_id: int
    data_type: str
    min_value: float
    max_value: float
    patient_profiles: Optional[dict] = None

class PaginatedThresholdsResponse(BaseModel):
    total_items: int
    total_pages: int
    current_page: int
    page_size: int
    data: List[PatientThresholdAdminView]

# --- Router Definition ---

router = APIRouter(
    prefix="/admin",
    tags=["Admin (Global Management)"],
    dependencies=[Depends(get_current_admin_user)] # Protect all routes in this router
)

# --- Endpoints ---

@router.get("/patients", summary="Get a list of all patients", response_model=PaginatedPatientsResponse)
async def get_all_patients(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
):
    """Retrieves a paginated list of all patient profiles in the system."""
    try:
        from_row = (page - 1) * page_size
        to_row = from_row + page_size - 1

        # Select all columns from patient_profiles and related data from foreign tables
        query = supabase.table('patient_profiles').select(
            "*, "
            "organisations(name), "
            "clinician_profiles(name)",
            count='exact'
        ).order('id', desc=True).range(from_row, to_row)
        
        patients_response = await query.execute()

        # Add calculated age to each patient profile
        patients = patients_response.data
        for patient in patients:
            patient['age'] = calculate_age(patient.get("date_of_birth"))
        
        return create_paginated_response(
            query_response_data=patients,
            query_response_count=patients_response.count,
            page=page,
            page_size=page_size
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve patients: {str(e)}")


@router.post("/patients", summary="Add a new patient")
async def add_patient_by_admin(patient_data: PatientAdminCreate):
    """Creates a new patient, including their authentication user and profile."""
    new_user = None
    try:
        # Step 1: Create the user in Supabase Auth
        user_session = await supabase.auth.admin.create_user({
            "email": patient_data.email,
            "password": patient_data.password,
            "email_confirm": True,  # Auto-confirm user
            "app_metadata": {"role": "PATIENT"}
        })
        new_user = user_session.user
        if not new_user:
            raise HTTPException(status_code=500, detail="Failed to create user in authentication system.")

        # Step 2: Call the database function to create the profile and default thresholds atomically.
        rpc_params = {
            "p_user_id": str(new_user.id),
            "p_name": patient_data.name,
            "p_phone_number": patient_data.phone_number,
            "p_gender": patient_data.gender,
            "p_date_of_birth": patient_data.date_of_birth.isoformat() if patient_data.date_of_birth else None,
            "p_emergency_contact_name": patient_data.emergency_contact_name,
            "p_emergency_contact_relationship": patient_data.emergency_contact_relationship,
            "p_emergency_contact_phone": patient_data.emergency_contact_phone,
            "p_risk_level": patient_data.risk_level.value,
            "p_organisation_id": patient_data.organisation_id,
            "p_clinician_id": patient_data.clinician_id,
        }
        
        patient_profile_res = await supabase.rpc('create_patient_with_profile_and_thresholds', rpc_params).execute()

        if not patient_profile_res.data:
            raise Exception("Failed to create patient profile and thresholds in database via RPC.")
        
        patient_profile = patient_profile_res.data[0]

        return {"message": "Patient created successfully.", "profile": patient_profile}

    except AuthApiError as e:
        logging.error(f"AuthApiError during patient creation: {e.message}")
        raise HTTPException(status_code=400, detail=f"User creation failed: {e.message}")
    except Exception as e:
        # Log the full traceback for debugging
        logging.exception("Failed to create patient.")
        # Rollback: delete the auth user if profile creation failed
        if new_user:
            await supabase.auth.admin.delete_user(new_user.id)
        raise HTTPException(status_code=500, detail=f"Failed to create patient: {str(e)}")


@router.get("/clinicians", summary="Get a list of all clinicians and their assigned patients", response_model=PaginatedCliniciansResponse)
async def get_all_clinicians(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
):
    """Retrieves a paginated list of all clinicians, their details, and the names of patients assigned to them."""
    try:
        from_row = (page - 1) * page_size
        to_row = from_row + page_size - 1

        # Fetch clinicians with their organisation and assigned patients' names
        query = supabase.table('clinician_profiles').select(
            "*, " # Select all columns from clinician_profiles
            "organisations(name), "
            "patient_profiles(name)",
            count='exact'
        ).order('id', desc=True).range(from_row, to_row)
        
        clinicians_response = await query.execute()

        # Process the data to simplify the nested patient list
        clinicians = clinicians_response.data
        for clinician in clinicians:
            # Replace the list of patient profile objects with just a list of names for simplicity
            patients_data = clinician.get('patient_profiles', [])
            clinician['assigned_patients'] = [patient['name'] for patient in patients_data if patient.get('name')]
            del clinician['patient_profiles'] # Remove the original nested list
        
        return create_paginated_response(
            query_response_data=clinicians,
            query_response_count=clinicians_response.count,
            page=page,
            page_size=page_size
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve clinicians: {str(e)}")


@router.post("/clinicians", summary="Add a new clinician")
async def add_clinician_by_admin(clinician_data: ClinicianAdminCreate):
    """Creates a new clinician, including their authentication user and profile."""
    new_user = None
    try:
        # Step 1: Validate that the organisation exists before creating a user.
        org_check = await supabase.table('organisations').select('id', count='exact').eq('id', clinician_data.organisation_id).execute()
        if org_check.count == 0:
            raise HTTPException(status_code=404, detail=f"Organisation with id {clinician_data.organisation_id} not found.")

        # Step 2: Create the user in Supabase Auth
        user_session = await supabase.auth.admin.create_user({
            "email": clinician_data.email,
            "password": clinician_data.password,
            "email_confirm": True,  # Auto-confirm user
            "app_metadata": {"role": "CLINICIAN"}
        })
        new_user = user_session.user
        if not new_user:
            raise HTTPException(status_code=500, detail="Failed to create user in authentication system.")

        # Step 3: Call the database function to create the profile atomically.
        rpc_params = {
            "p_user_id": str(new_user.id),
            "p_name": clinician_data.name,
            "p_phone_number": clinician_data.phone_number,
            "p_gender": clinician_data.gender,
            "p_organisation_id": clinician_data.organisation_id,
        }
        clinician_profile_res = await supabase.rpc('create_clinician_with_profile', rpc_params).execute()
        if not clinician_profile_res.data:
            raise Exception("Failed to create clinician profile in database via RPC.")
        
        clinician_profile = clinician_profile_res.data[0]

        return {"message": "Clinician created successfully.", "profile": clinician_profile}

    except AuthApiError as e:
        logging.error(f"AuthApiError during clinician creation: {e.message}")
        raise HTTPException(status_code=400, detail=f"User creation failed: {e.message}")
    except Exception as e:
        # Rollback: delete the auth user if profile creation failed
        logging.exception("Failed to create clinician.")
        if new_user:
            await supabase.auth.admin.delete_user(new_user.id)
        raise HTTPException(status_code=500, detail=f"Failed to create clinician: {str(e)}")


@router.get("/organisations", summary="Get a list of all organisations", response_model=PaginatedOrganisationsResponse)
async def get_all_organisations(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
):
    """Retrieves a paginated list of all organisations in the system."""
    try:
        from_row = (page - 1) * page_size
        to_row = from_row + page_size - 1

        query = supabase.table('organisations').select('*', count='exact').order('id', desc=True).range(from_row, to_row)
        organisations_response = await query.execute()
        
        return create_paginated_response(
            query_response_data=organisations_response.data,
            query_response_count=organisations_response.count,
            page=page,
            page_size=page_size
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve organisations: {str(e)}")


@router.post("/organisations", summary="Add a new organisation")
async def add_organisation_by_admin(org_data: OrganisationAdminCreate):
    """Creates a new organisation."""
    try:
        response = await supabase.table('organisations').insert({"name": org_data.name}).execute()
        if not response.data:
            raise HTTPException(status_code=500, detail="Failed to create organisation.")
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create organisation: {str(e)}")


@router.get("/daily-logs", summary="Get a list of all daily patient logs", response_model=PaginatedDailyLogsResponse)
async def get_all_daily_logs(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(50, ge=1, le=100, description="Items per page"),
):
    """Retrieves a paginated list of all daily patient logs with patient names."""
    try:
        from_row = (page - 1) * page_size
        to_row = from_row + page_size - 1

        query = supabase.table('daily_patient_logs').select(
            "*, " # Select all columns from daily_patient_logs
            "patient_profiles(name)",
            count='exact'
        ).order('log_date', desc=True).order('id', desc=True).range(from_row, to_row)
        
        logs_response = await query.execute()
        
        return create_paginated_response(
            query_response_data=logs_response.data,
            query_response_count=logs_response.count,
            page=page,
            page_size=page_size
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve daily logs: {str(e)}")


@router.post("/daily-logs", summary="Add a daily patient log")
async def add_daily_log_by_admin(log_data: DailyLogAdminCreate):
    """Adds a new daily log entry for a specified patient."""
    try:
        insert_dict = log_data.model_dump(mode='json')
        
        # Check if patient exists
        patient_check = await supabase.table('patient_profiles').select('id', count='exact').eq('id', log_data.patient_id).execute()
        if patient_check.count == 0:
            raise HTTPException(status_code=404, detail=f"Patient with id {log_data.patient_id} not found.")

        new_log_response = await supabase.table('daily_patient_logs').insert(insert_dict).execute()
        if not new_log_response.data:
            raise HTTPException(status_code=500, detail="Failed to create daily log.")
        return new_log_response.data[0]
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except APIError as e:
        if e.code == "23505": # unique_violation
            raise HTTPException(status_code=409, detail="A log for this patient, date and meal time already exists.")
        raise HTTPException(status_code=500, detail=f"Database error while adding daily log: {e.message}")
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add daily log: {str(e)}")


@router.delete("/daily-logs/{log_id}", summary="Remove a daily patient log")
async def delete_daily_log_by_admin(log_id: int):
    """Deletes a daily patient log entry by its ID."""
    try:
        response = await supabase.table('daily_patient_logs').delete().eq('id', log_id).execute()
        if not response.data:
            raise HTTPException(status_code=404, detail=f"Daily log with id {log_id} not found.")
        return {"message": f"Daily log with id {log_id} deleted successfully."}
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete daily log: {str(e)}")


@router.get("/monitor-data", summary="Get a list of all patient monitor data", response_model=PaginatedMonitorDataResponse)
async def get_all_monitor_data(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(50, ge=1, le=100, description="Items per page"),
):
    """Retrieves a paginated list of all patient monitor data points with patient names."""
    try:
        from_row = (page - 1) * page_size
        to_row = from_row + page_size - 1

        query = supabase.table('patient_monitor_data').select(
            "*, " # Select all columns from patient_monitor_data
            "patient_profiles(name)",
            count='exact'
        ).order('measured_at', desc=True).range(from_row, to_row)

        data_response = await query.execute()

        # Add unit information to each data point
        for item in data_response.data:
            data_type_str = item.get("data_type")
            if data_type_str:
                try:
                    item['unit'] = MonitorDataType(data_type_str).unit
                except ValueError:
                    item['unit'] = 'N/A' # Handle cases where data_type is not in the enum
            else:
                item['unit'] = 'N/A'
        
        return create_paginated_response(
            query_response_data=data_response.data,
            query_response_count=data_response.count,
            page=page,
            page_size=page_size
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve monitor data: {str(e)}")


@router.post("/monitor-data", summary="Add a patient monitor data point")
async def add_monitor_data_by_admin(data: MonitorDataAdminCreate):
    """Adds a new health monitor data point for a specified patient."""
    insert_dict = data.model_dump(mode='json')
    try:
        # Check if patient exists
        patient_check = await supabase.table('patient_profiles').select('id', count='exact').eq('id', data.patient_id).execute()
        if patient_check.count == 0:
            raise HTTPException(status_code=404, detail=f"Patient with id {data.patient_id} not found.")

        new_data_response = await supabase.table('patient_monitor_data').insert(insert_dict).execute()
        if not new_data_response.data:
            raise HTTPException(status_code=500, detail="Failed to create monitor data point.")
        return new_data_response.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add monitor data: {str(e)}")


@router.delete("/monitor-data/{data_id}", summary="Remove a patient monitor data point")
async def delete_monitor_data_by_admin(data_id: int):
    """Deletes a patient monitor data point by its ID."""
    try:
        response = await supabase.table('patient_monitor_data').delete().eq('id', data_id).execute()
        if not response.data:
            raise HTTPException(status_code=404, detail=f"Monitor data with id {data_id} not found.")
        return {"message": f"Monitor data with id {data_id} deleted successfully."}
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete monitor data: {str(e)}")


@router.get("/thresholds", summary="Get a list of all patient thresholds", response_model=PaginatedThresholdsResponse)
async def get_all_thresholds(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(50, ge=1, le=100, description="Items per page"),
):
    """Retrieves a paginated list of all patient thresholds with patient names."""
    try:
        from_row = (page - 1) * page_size
        to_row = from_row + page_size - 1

        query = supabase.table('patient_thresholds').select(
            "*, " # Select all columns from patient_thresholds
            "patient_profiles(name)",
            count='exact'
        ).order('patient_id').order('id').range(from_row, to_row)
        
        thresholds_response = await query.execute()
        
        return create_paginated_response(
            query_response_data=thresholds_response.data,
            query_response_count=thresholds_response.count,
            page=page,
            page_size=page_size
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve thresholds: {str(e)}")


@router.put("/patients/{patient_id}", summary="Edit any patient (including risk level)")
async def update_patient_by_admin(patient_id: int, update_data: PatientProfileAdminUpdate):
    """Updates any patient's profile. Can be used to change risk level or other details."""
    update_dict = update_data.model_dump(mode='json', exclude_unset=True)
    ensure_not_empty(update_dict)

    try:
        updated_profile_response = await supabase.table('patient_profiles').update(update_dict).eq('id', patient_id).execute()
        if not updated_profile_response.data:
            raise HTTPException(status_code=404, detail=f"Patient with id {patient_id} not found.")
        return updated_profile_response.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update patient profile: {str(e)}")


@router.put("/clinicians/{clinician_id}", summary="Edit any clinician")
async def update_clinician_by_admin(clinician_id: int, update_data: ClinicianProfileAdminUpdate):
    """Updates any clinician's profile."""
    update_dict = update_data.model_dump(mode='json', exclude_unset=True)
    ensure_not_empty(update_dict)

    try:
        updated_profile_response = await supabase.table('clinician_profiles').update(update_dict).eq('id', clinician_id).execute()
        if not updated_profile_response.data:
            raise HTTPException(status_code=404, detail=f"Clinician with id {clinician_id} not found.")
        return updated_profile_response.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update clinician profile: {str(e)}")


@router.put("/organisations/{organisation_id}", summary="Edit any organisation")
async def update_organisation_by_admin(organisation_id: int, update_data: OrganisationAdminUpdate):
    """Updates any organisation's details."""
    update_dict = update_data.model_dump(mode='json', exclude_unset=True)
    ensure_not_empty(update_dict)

    try:
        response = await supabase.table('organisations').update(update_dict).eq('id', organisation_id).execute()
        if not response.data:
            raise HTTPException(status_code=404, detail=f"Organisation with id {organisation_id} not found.")
        return response.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update organisation: {str(e)}")


@router.delete("/organisations/{organisation_id}", summary="Remove any organisation")
async def delete_organisation_by_admin(organisation_id: int):
    """
    Deletes an organisation. This is only possible if no clinicians or patients
    are currently assigned to it.
    """
    try:
        # Step 1: Check if any clinicians are assigned to this organisation.
        clinician_check = await supabase.table('clinician_profiles').select('id', count='exact').eq('organisation_id', organisation_id).execute()
        if clinician_check.count > 0:
            raise HTTPException(
                status_code=409, # Conflict
                detail=f"Cannot delete organisation {organisation_id} because it has {clinician_check.count} clinician(s) assigned. Please reassign or delete them first."
            )

        # Step 2: Check if any patients are assigned to this organisation.
        patient_check = await supabase.table('patient_profiles').select('id', count='exact').eq('organisation_id', organisation_id).execute()
        if patient_check.count > 0:
            raise HTTPException(
                status_code=409, # Conflict
                detail=f"Cannot delete organisation {organisation_id} because it has {patient_check.count} patient(s) assigned. Please unassign them first."
            )

        # Step 3: Delete the organisation.
        response = await supabase.table('organisations').delete().eq('id', organisation_id).execute()

        if not response.data:
            raise HTTPException(status_code=404, detail=f"Organisation with id {organisation_id} not found.")

        return {"message": f"Organisation with id {organisation_id} deleted successfully."}
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete organisation: {str(e)}")


@router.put("/daily-logs/{log_id}", summary="Edit any daily patient log")
async def update_daily_log_by_admin(log_id: int, update_data: DailyLogAdminUpdate):
    """Updates any daily patient log entry."""
    update_dict = update_data.model_dump(mode='json', exclude_unset=True)
    ensure_not_empty(update_dict)

    try:
        response = await supabase.table('daily_patient_logs').update(update_dict).eq('id', log_id).execute()
        if not response.data:
            raise HTTPException(status_code=404, detail=f"Daily log with id {log_id} not found.")
        return response.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update daily log: {str(e)}")


@router.put("/monitor-data/{data_id}", summary="Edit any patient monitor data point")
async def update_monitor_data_by_admin(data_id: int, update_data: MonitorDataAdminUpdate):
    """Updates any patient monitor data point."""
    update_dict = update_data.model_dump(mode='json', exclude_unset=True)
    ensure_not_empty(update_dict)

    try:
        response = await supabase.table('patient_monitor_data').update(update_dict).eq('id', data_id).execute()
        if not response.data:
            raise HTTPException(status_code=404, detail=f"Monitor data with id {data_id} not found.")
        return response.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update monitor data: {str(e)}")


@router.put("/thresholds/{threshold_id}", summary="Edit any patient threshold")
async def update_patient_threshold_by_admin(threshold_id: int, update_data: PatientThresholdAdminUpdate):
    """Updates any patient threshold entry."""
    update_dict = update_data.model_dump(mode='json', exclude_unset=True)
    ensure_not_empty(update_dict)

    try:
        response = await supabase.table('patient_thresholds').update(update_dict).eq('id', threshold_id).execute()
        if not response.data:
            raise HTTPException(status_code=404, detail=f"Threshold with id {threshold_id} not found.")
        return response.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update threshold: {str(e)}")


@router.put("/notes/{note_id}", summary="Edit any clinician note")
async def update_clinician_note_by_admin(note_id: int, update_data: ClinicianNoteAdminUpdate):
    """Updates any clinician note."""
    update_dict = update_data.model_dump(mode='json', exclude_unset=True)
    ensure_not_empty(update_dict)

    try:
        response = await supabase.table('clinician_notes').update(update_dict).eq('id', note_id).execute()
        if not response.data:
            raise HTTPException(status_code=404, detail=f"Note with id {note_id} not found.")
        return response.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update note: {str(e)}")


@router.delete("/patients/{patient_id}", summary="Remove any patient")
async def delete_patient_by_admin(patient_id: int):
    """
    Deletes a patient's profile from the database and also deletes the
    corresponding user from Supabase Auth.
    """
    try:
        # Step 1: Retrieve the patient's profile to get their user_id.
        patient_profile_res = await supabase.table('patient_profiles').select("user_id").eq('id', patient_id).single().execute()
        user_id = patient_profile_res.data.get("user_id")

        # Step 2: Delete the associated auth user.
        # The 'ON DELETE CASCADE' on the 'patient_profiles' table will automatically delete the profile.
        if user_id:
            try:
                await supabase.auth.admin.delete_user(user_id)
            except Exception as auth_error:
                # If auth user deletion fails, the profile remains, which is safe.
                raise HTTPException(
                    status_code=500, 
                    detail=f"Failed to delete auth user {user_id}. Aborting deletion. Error: {str(auth_error)}"
                )
        
        return {"message": f"Patient profile with id {patient_id} and associated auth user deleted successfully."}
    except APIError as e:
        if e.code == "PGRST116": # Not found
            raise HTTPException(status_code=404, detail=f"Patient with id {patient_id} not found.")
        raise HTTPException(status_code=500, detail=f"Database error: {e.message}")
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete patient: {str(e)}")


@router.delete("/clinicians/{clinician_id}", summary="Remove any clinician")
async def delete_clinician_by_admin(clinician_id: int):
    """
    Deletes a clinician's profile, unassigns their patients, preserves their notes,
    and deletes the corresponding user from Supabase Auth.
    """
    try:
        # Step 1: Retrieve the clinician's profile to get user_id and name.
        clinician_profile_res = await supabase.table('clinician_profiles').select("user_id, name").eq('id', clinician_id).single().execute()
        clinician_profile = clinician_profile_res.data
        user_id = clinician_profile.get("user_id")
        clinician_name = clinician_profile.get("name")

        # Step 2: Unassign all patients from this clinician.
        await supabase.table('patient_profiles').update({"clinician_id": None}).eq('clinician_id', clinician_id).execute()

        # Step 3: Preserve notes by detaching them from the clinician.
        await supabase.table('clinician_notes').update({
            "clinician_id": None,
            "clinician_name_snapshot": clinician_name
        }).eq('clinician_id', clinician_id).execute()

        # Step 4: Delete the associated auth user.
        # The 'ON DELETE CASCADE' on the 'clinician_profiles' table will automatically delete the profile.
        if user_id:
            try:
                await supabase.auth.admin.delete_user(user_id)
            except Exception as auth_error:
                raise HTTPException(
                    status_code=500,
                    detail=f"Failed to delete auth user {user_id}. Aborting deletion. Error: {str(auth_error)}"
                )

        return {"message": f"Clinician profile with id {clinician_id} and associated auth user deleted successfully."}
    except APIError as e:
        if e.code == "PGRST116": # Not found
            raise HTTPException(status_code=404, detail=f"Clinician with id {clinician_id} not found.")
        raise HTTPException(status_code=500, detail=f"Database error: {e.message}")
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete clinician: {str(e)}")


