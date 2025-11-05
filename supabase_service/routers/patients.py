import logging
from fastapi import APIRouter, Depends, HTTPException, Header, Query
from pydantic import BaseModel, model_validator
from typing import Optional, List
from supabase.lib.client_async import AsyncClient
from postgrest.exceptions import APIError
from datetime import date, timedelta, datetime

from ..models import MonitorDataType, MealTime
from ..core.dependencies import get_user_supabase_client
from ..core.utils import calculate_age, create_paginated_response, ensure_not_empty

# --- Pydantic Models ---

class PatientProfileUpdate(BaseModel):
    """Fields a patient is allowed to update on their own profile."""
    name: Optional[str] = None
    phone_number: Optional[str] = None
    gender: Optional[str] = None
    date_of_birth: Optional[date] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_relationship: Optional[str] = None
    emergency_contact_phone: Optional[str] = None

class MonitorDataCreate(BaseModel):
    data_type: MonitorDataType
    value: float
    measured_at: datetime

class MonitorDataUpdate(BaseModel):
    value: Optional[float] = None
    measured_at: Optional[datetime] = None

class DailyLogCreate(BaseModel):
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


class MonitorDataPoint(BaseModel):
    id: int
    data_type: str
    value: float
    measured_at: datetime

class PaginatedMonitorDataResponse(BaseModel):
    total_items: int
    total_pages: int
    current_page: int
    page_size: int
    data: List[MonitorDataPoint]

class DailyLogEntry(BaseModel):
    id: int
    log_date: date
    meal_time: MealTime
    glucose_before_meal: Optional[float] = None
    glucose_after_meal: Optional[float] = None
    meal_desc: Optional[str] = None

class PaginatedDailyLogResponse(BaseModel):
    total_items: int
    total_pages: int
    current_page: int
    page_size: int
    data: List[DailyLogEntry]

# --- Router Definition ---

router = APIRouter(
    prefix="/patients",
    tags=["Patient (Self-Service)"]
)

# --- Helper Functions / Dependencies ---

async def get_current_patient_profile(supabase: AsyncClient = Depends(get_user_supabase_client)):
    """
    A FastAPI dependency that authenticates the current user as a patient
    by fetching their profile. RLS ensures this only succeeds if they are a patient.
    """
    try:
        profile_response = await supabase.table('patient_profiles').select('*').single().execute()
        return profile_response.data
    except APIError as e:
        if e.code == "PGRST116": # "JSON object requested, but 0 rows returned"
            raise HTTPException(status_code=403, detail="Access denied: User is not a patient or profile not found.")
        logging.error(f"Database error fetching patient profile: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")
    except Exception as e:
        logging.error(f"Unexpected error fetching patient profile: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")


@router.get("/me", summary="Get my own full patient profile")
async def get_own_patient_profile(patient_profile: dict = Depends(get_current_patient_profile)):
    """
    Retrieves the complete profile for the currently authenticated patient.
    RLS ensures they can only access their own profile.
    """
    profile_with_age = patient_profile.copy()
    profile_with_age['age'] = calculate_age(profile_with_age.get("date_of_birth"))
    return profile_with_age


@router.put("/me", summary="Update my own patient profile")
async def update_own_patient_profile(
    update_data: PatientProfileUpdate,
    patient_profile: dict = Depends(get_current_patient_profile),
    supabase: AsyncClient = Depends(get_user_supabase_client)
):
    """
    Updates the profile of the currently authenticated patient.
    RLS ensures a patient can only update their own profile.
    """
    update_dict = update_data.model_dump(mode='json', exclude_unset=True)
    ensure_not_empty(update_dict)

    try:
        # RLS on 'patient_profiles' restricts this update, but the client library
        # also requires a filter to prevent accidental full-table updates.
        # We use the patient's own ID, fetched securely via the get_current_patient_profile dependency.
        patient_id = patient_profile['id']
        updated_profile_response = await supabase.table('patient_profiles').update(update_dict).eq('id', patient_id).execute()
        if not updated_profile_response.data:
            # This could happen if RLS fails or the profile is gone.
            raise HTTPException(status_code=404, detail="Patient profile not found or update failed.")
        return updated_profile_response.data[0]
    except Exception as e:
        logging.error(f"Failed to update patient profile: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")


@router.get("/me/monitor-data", response_model=PaginatedMonitorDataResponse, summary="Get my paginated monitor data")
async def get_own_monitor_data(
    supabase: AsyncClient = Depends(get_user_supabase_client),
    # --- Filtering Parameters ---
    start_date: Optional[date] = None,
    end_date: Optional[date] = date.today(),
    data_type: Optional[MonitorDataType] = Query(None),

    # --- Pagination Parameters ---
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(50, ge=1, le=100, description="Items per page"),
):
    """
    Retrieves paginated and filtered health monitor data for the currently
    authenticated patient. Data is sorted by most recent first.
    """
    # Default start_date to 30 days ago if not provided
    if start_date is None:
        start_date = end_date - timedelta(days=30)
        
    # Calculate the query range for pagination
    from_row = (page - 1) * page_size
    to_row = from_row + page_size - 1
    
    try:
        # RLS automatically filters to the current patient's data.
        query = supabase.table('patient_monitor_data').select(
            "id, data_type, value, measured_at", 
            count='exact'
        )

        # Apply optional filters
        if start_date:
            query = query.gte('measured_at', str(start_date))
        if end_date:
            # Add one day to end_date to make it inclusive of the whole day
            inclusive_end_date = end_date + timedelta(days=1)
            query = query.lt('measured_at', str(inclusive_end_date))
        if data_type:
            query = query.eq('data_type', data_type.value)
        
        # 3. Apply sorting and pagination
        query = query.order('measured_at', desc=True).range(from_row, to_row)

        # Execute the query
        response = await query.execute()
        
        return create_paginated_response(
            query_response_data=response.data,
            query_response_count=response.count,
            page=page,
            page_size=page_size
        )

    except Exception as e:
        logging.error(f"An error occurred while fetching monitor data: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")


@router.post("/me/monitor-data", summary="Add a new monitor data point for myself")
async def add_own_monitor_data(
    data: MonitorDataCreate,
    patient_profile: dict = Depends(get_current_patient_profile),
    supabase: AsyncClient = Depends(get_user_supabase_client)
):
    """
    Adds a new health monitor data point for the authenticated patient.
    RLS ensures the patient_id is correct.
    """
    insert_dict = data.model_dump(mode='json')
    insert_dict['patient_id'] = patient_profile['id'] # Still need to associate with the profile
    try:
        new_data_response = await supabase.table('patient_monitor_data').insert(insert_dict).execute()
        return new_data_response.data[0]
    except Exception as e:
        logging.error(f"Failed to add monitor data: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")


@router.put("/me/monitor-data/{data_id}", summary="Update one of my monitor data entries")
async def update_own_monitor_data(
    data_id: int,
    update_data: MonitorDataUpdate,
    supabase: AsyncClient = Depends(get_user_supabase_client)
):
    """
    Updates a specific health monitor data entry. RLS ensures the user can only
    update their own entries.
    """
    update_dict = update_data.model_dump(mode='json', exclude_unset=True)
    ensure_not_empty(update_dict)

    try:
        # RLS policy on 'patient_monitor_data' handles the authorization check.
        updated_data_response = await supabase.table('patient_monitor_data').update(update_dict).eq('id', data_id).execute()
        
        if not updated_data_response.data:
            raise HTTPException(status_code=404, detail="Monitor data entry not found or access denied.")

        return updated_data_response.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        logging.error(f"Failed to update monitor data: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")


@router.get("/me/daily-logs", response_model=PaginatedDailyLogResponse, summary="Get my paginated daily logs")
async def get_own_daily_logs(
    supabase: AsyncClient = Depends(get_user_supabase_client),
    # --- Filtering Parameters ---
    start_date: Optional[date] = None,
    end_date: Optional[date] = date.today(),
    meal_time: Optional[MealTime] = Query(None),

    # --- Pagination Parameters ---
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(50, ge=1, le=100, description="Items per page"),
):
    """
    Retrieves paginated and filtered daily logs for the currently
    authenticated patient. Data is sorted by most recent first.
    """
    # Default start_date to 30 days ago if not provided
    if start_date is None:
        start_date = end_date - timedelta(days=30)
        
    # Calculate the query range for pagination
    from_row = (page - 1) * page_size
    to_row = from_row + page_size - 1
    
    try:
        # RLS automatically filters to the current patient's logs.
        query = supabase.table('daily_patient_logs').select(
            "id, log_date, meal_time, glucose_before_meal, glucose_after_meal, meal_desc", 
            count='exact'
        )

        # Apply optional filters
        if start_date:
            query = query.gte('log_date', str(start_date))
        if end_date:
            query = query.lte('log_date', str(end_date))
        if meal_time:
            query = query.eq('meal_time', meal_time.value)
        
        # 3. Apply sorting and pagination
        query = query.order('log_date', desc=True).order('meal_time', desc=True).range(from_row, to_row)

        # Execute the query
        response = await query.execute()
        
        return create_paginated_response(
            query_response_data=response.data,
            query_response_count=response.count,
            page=page,
            page_size=page_size
        )

    except Exception as e:
        logging.error(f"An error occurred while fetching daily logs: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")


@router.post("/me/daily-logs", summary="Add a new daily log for myself")
async def add_own_daily_log(
    log_data: DailyLogCreate,
    patient_profile: dict = Depends(get_current_patient_profile),
    supabase: AsyncClient = Depends(get_user_supabase_client)
):
    """
    Adds a new daily log entry for the currently authenticated patient.
    """
    try:
        insert_dict = log_data.model_dump(mode='json')
        insert_dict['patient_id'] = patient_profile['id']
        
        new_log_response = await supabase.table('daily_patient_logs').insert(insert_dict).execute()
        return new_log_response.data[0]
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except APIError as e:
        if e.code == "23505": # unique_violation
            raise HTTPException(status_code=409, detail="A log for this date and meal time already exists.")
        logging.error(f"Database error while adding daily log: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")
    except Exception as e:
        logging.error(f"Failed to add daily log: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")


@router.get("/me/thresholds", summary="Get my own defined health thresholds")
async def get_own_thresholds(supabase: AsyncClient = Depends(get_user_supabase_client)):
    """
    Retrieves the health thresholds for the authenticated patient.
    RLS ensures they can only see their own thresholds.
    """
    try:
        thresholds_response = await supabase.table('patient_thresholds').select('*').execute()
        return thresholds_response.data
    except Exception as e:
        logging.error(f"Failed to retrieve thresholds: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")

