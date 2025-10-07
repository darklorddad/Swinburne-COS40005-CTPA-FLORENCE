from fastapi import APIRouter, Depends, HTTPException, Header, Query
from pydantic import BaseModel, model_validator
from typing import Optional, List
from supabase_auth.errors import AuthApiError
from datetime import datetime, date, timedelta
from enum import Enum
import math

from ..client import supabase

# --- Helper Functions / Dependencies ---

async def get_current_patient_profile(authorization: str = Header(...)):
    """
    A FastAPI dependency that authenticates the current user as a patient.

    It validates the JWT from the 'Authorization' header, confirms the user
    is a patient by checking for a corresponding entry in the `patient_profiles`
    table, and returns the full patient profile.

    Args:
        authorization (str): The 'Authorization: Bearer <token>' header.

    Returns:
        dict: The full profile of the authenticated patient from the
              `patient_profiles` table.

    Raises:
        HTTPException(401): If the authentication scheme is invalid or the token
                             is expired or incorrect.
        HTTPException(403): If the authenticated user is not a patient.
        HTTPException(500): For any other server-side errors during the process.
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authentication scheme.")
    
    token = authorization.split(" ")[1]
    
    try:
        user_response = supabase.auth.get_user(token)
        user = user_response.user
        if not user:
            raise HTTPException(status_code=401, detail="Invalid token.")
        
        # Fetch the patient profile using the user's ID. This now serves as the role check.
        profile_response = supabase.table('patient_profiles').select('*').eq('user_id', user.id).single().execute()
            
        return profile_response.data
    except AuthApiError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e.message}")
    except Exception as e:
        # This will catch the .single() error if more than one profile is found
        if "Multiple rows returned" in str(e):
             raise HTTPException(status_code=500, detail="Fatal: Multiple profiles found for a single user.")
        # If no rows are found, .single() raises an error. We treat this as an access denied case.
        if "Expected 1 row, got 0" in str(e):
            raise HTTPException(status_code=403, detail="Access denied: User is not a patient.")
        raise HTTPException(status_code=500, detail=str(e))

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

class MonitorDataType(str, Enum):
    BLOOD_PRESSURE_SYSTOLIC = 'BLOOD_PRESSURE_SYSTOLIC'
    BLOOD_PRESSURE_DIASTOLIC = 'BLOOD_PRESSURE_DIASTOLIC'
    GLUCOSE = 'GLUCOSE'
    BMI = 'BMI'
    HBA1C = 'HBA1C'
    ECG = 'ECG'
    CHOLESTEROL = 'CHOLESTEROL'

class MonitorDataCreate(BaseModel):
    data_type: MonitorDataType
    value: float
    measured_at: datetime

class MonitorDataUpdate(BaseModel):
    value: Optional[float] = None
    measured_at: Optional[datetime] = None

class MealTime(str, Enum):
    BREAKFAST = 'BREAKFAST'
    LUNCH = 'LUNCH'
    DINNER = 'DINNER'

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


@router.get("/me", summary="Get my own full patient profile")
async def get_own_patient_profile(patient_profile: dict = Depends(get_current_patient_profile)):
    """
    Retrieves the complete profile for the currently authenticated patient,
    including their age, gender, and date of birth.
    """
    profile_with_age = patient_profile.copy()
    dob_str = profile_with_age.get("date_of_birth")
    
    if dob_str:
        try:
            dob = date.fromisoformat(dob_str)
            today = date.today()
            age = today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))
            profile_with_age['age'] = age
        except (ValueError, TypeError):
            profile_with_age['age'] = None
    else:
        profile_with_age['age'] = None
            
    return profile_with_age


@router.put("/me", summary="Update my own patient profile")
async def update_own_patient_profile(
    update_data: PatientProfileUpdate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """
    Updates the profile of the currently authenticated patient.

    Allows a patient to update their own profile information.
    Only fields provided in the request body are updated.
    """
    update_dict = update_data.model_dump(mode='json', exclude_unset=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No update data provided.")

    try:
        updated_profile_response = supabase.table('patient_profiles').update(update_dict).eq('id', patient_profile['id']).execute()
        if not updated_profile_response.data:
            raise HTTPException(status_code=404, detail="Patient profile not found.")
        return updated_profile_response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update profile: {str(e)}")


@router.delete("/me", summary="Delete my own patient profile")
async def delete_own_patient_profile(patient_profile: dict = Depends(get_current_patient_profile)):
    """
    Deletes the currently authenticated patient's profile and the corresponding
    user from Supabase Auth. All related data (monitor data, logs, etc.)
    will be deleted via database cascade rules.
    """
    try:
        patient_id = patient_profile.get("id")
        user_id = patient_profile.get("user_id")

        # Step 1: Delete the patient's profile.
        # The database is configured with ON DELETE CASCADE, so this will trigger
        # the deletion of all related data in other tables.
        deleted_profile_response = supabase.table('patient_profiles').delete().eq('id', patient_id).execute()
        
        if not deleted_profile_response.data:
            raise HTTPException(status_code=500, detail=f"Failed to delete own patient profile {patient_id} after it was found.")
        
        # Step 2: If there's an associated auth user, delete them.
        if not user_id:
            return {"message": f"Patient profile with id {patient_id} deleted, but no associated auth user to delete."}

        try:
            supabase.auth.admin.delete_user(user_id)
        except Exception as auth_error:
            raise HTTPException(
                status_code=500, 
                detail=f"Patient profile {patient_id} deleted, but failed to delete user {user_id} from auth: {str(auth_error)}"
            )

        return {"message": f"Patient profile with id {patient_id} and associated auth user deleted successfully."}
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete own patient profile: {str(e)}")


@router.get("/me/monitor-data", response_model=PaginatedMonitorDataResponse, summary="Get my paginated monitor data")
async def get_own_monitor_data(
    patient_profile: dict = Depends(get_current_patient_profile),
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
    
    patient_id = patient_profile['id']

    try:
        query = supabase.table('patient_monitor_data').select(
            "id, data_type, value, measured_at", 
            count='exact'
        )

        # 1. Filter by the logged-in patient's ID
        query = query.eq('patient_id', patient_id)

        # 2. Apply optional filters
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
        response = query.execute()
        
        data_points = response.data
        total_items = response.count if response.count is not None else 0
        total_pages = math.ceil(total_items / page_size) if total_items > 0 else 0

        return {
            "total_items": total_items,
            "total_pages": total_pages,
            "current_page": page,
            "page_size": page_size,
            "data": data_points
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred while fetching monitor data: {str(e)}")


@router.post("/me/monitor-data", summary="Add a new monitor data point for myself")
async def add_own_monitor_data(
    data: MonitorDataCreate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """
    Adds a new health monitor data point for the authenticated patient.
    """
    insert_dict = data.model_dump(mode='json')
    insert_dict['patient_id'] = patient_profile['id']
    try:
        new_data_response = supabase.table('patient_monitor_data').insert(insert_dict).execute()
        return new_data_response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add monitor data: {str(e)}")


@router.put("/me/monitor-data/{data_id}", summary="Update one of my monitor data entries")
async def update_own_monitor_data(
    data_id: int,
    update_data: MonitorDataUpdate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """
    Updates a specific health monitor data entry for the authenticated patient.
    """
    update_dict = update_data.model_dump(mode='json', exclude_unset=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No update data provided.")

    try:
        # Verify the data point belongs to the patient before updating
        existing_data_res = supabase.table('patient_monitor_data').select('id', count='exact').eq('id', data_id).eq('patient_id', patient_profile['id']).execute()
        if existing_data_res.count == 0:
            raise HTTPException(status_code=404, detail="Monitor data entry not found or access denied.")

        updated_data_response = supabase.table('patient_monitor_data').update(update_dict).eq('id', data_id).execute()
        return updated_data_response.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update monitor data: {str(e)}")


@router.get("/me/daily-logs", response_model=PaginatedDailyLogResponse, summary="Get my paginated daily logs")
async def get_own_daily_logs(
    patient_profile: dict = Depends(get_current_patient_profile),
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
    
    patient_id = patient_profile['id']

    try:
        query = supabase.table('daily_patient_logs').select(
            "id, log_date, meal_time, glucose_before_meal, glucose_after_meal, meal_desc", 
            count='exact'
        )

        # 1. Filter by the logged-in patient's ID
        query = query.eq('patient_id', patient_id)

        # 2. Apply optional filters
        if start_date:
            query = query.gte('log_date', str(start_date))
        if end_date:
            query = query.lte('log_date', str(end_date))
        if meal_time:
            query = query.eq('meal_time', meal_time.value)
        
        # 3. Apply sorting and pagination
        query = query.order('log_date', desc=True).order('meal_time', desc=True).range(from_row, to_row)

        # Execute the query
        response = query.execute()
        
        log_entries = response.data
        total_items = response.count if response.count is not None else 0
        total_pages = math.ceil(total_items / page_size) if total_items > 0 else 0

        return {
            "total_items": total_items,
            "total_pages": total_pages,
            "current_page": page,
            "page_size": page_size,
            "data": log_entries
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred while fetching daily logs: {str(e)}")


@router.post("/me/daily-logs", summary="Add a new daily log for myself")
async def add_own_daily_log(
    log_data: DailyLogCreate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """
    Adds a new daily log entry for the currently authenticated patient.
    """
    try:
        insert_dict = log_data.model_dump(mode='json')
        insert_dict['patient_id'] = patient_profile['id']
        
        new_log_response = supabase.table('daily_patient_logs').insert(insert_dict).execute()
        return new_log_response.data[0]
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        if "duplicate key value violates unique constraint" in str(e):
            raise HTTPException(status_code=409, detail="A log for this date and meal time already exists.")
        raise HTTPException(status_code=500, detail=f"Failed to add daily log: {str(e)}")


@router.get("/me/thresholds", summary="Get my own defined health thresholds")
async def get_own_thresholds(patient_profile: dict = Depends(get_current_patient_profile)):
    """
    Retrieves the set of health thresholds defined for the currently authenticated patient.
    """
    try:
        thresholds_response = supabase.table('patient_thresholds').select('*').eq('patient_id', patient_profile['id']).execute()
        return thresholds_response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve thresholds: {str(e)}")

