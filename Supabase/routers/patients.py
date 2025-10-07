from fastapi import APIRouter, Depends, HTTPException, Header
from pydantic import BaseModel, model_validator
from typing import Optional
from supabase_auth.errors import AuthApiError
from datetime import datetime, date
from enum import Enum

from ..client import supabase

# --- Helper Functions / Dependencies ---

async def get_current_patient_profile(authorization: str = Header(...)):
    """
    Dependency to get the current user, verify they are a patient,
    and return their full profile from the `patient_profiles` table.
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

    @model_validator(mode='before')
    @classmethod
    def check_at_least_one_glucose_reading(cls, values):
        before, after = values.get('glucose_before_meal'), values.get('glucose_after_meal')
        if before is None and after is None:
            raise ValueError('At least one of glucose_before_meal or glucose_after_meal must be provided.')
        return values

# --- Router Definition ---

router = APIRouter(
    prefix="/patients",
    tags=["Patient (Self-Service)"]
)

@router.get("/me", summary="Get my own full patient profile")
async def get_own_patient_profile(patient_profile: dict = Depends(get_current_patient_profile)):
    """
    Retrieves the complete profile for the currently authenticated patient,
    including details from the `patient_profiles` table.
    """
    return patient_profile

@router.put("/me", summary="Update my own patient profile")
async def update_own_patient_profile(
    update_data: PatientProfileUpdate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """
    Updates editable fields on the currently authenticated patient's profile.
    Only fields provided in the request body will be updated.
    """
    update_dict = update_data.model_dump(exclude_unset=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No update data provided.")

    try:
        updated_profile_response = supabase.table('patient_profiles').update(update_dict).eq('id', patient_profile['id']).execute()
        return updated_profile_response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update profile: {str(e)}")

@router.get("/me/monitor-data", summary="Get all my monitor data")
async def get_own_monitor_data(patient_profile: dict = Depends(get_current_patient_profile)):
    """
    Retrieves all health monitor data (e.g., blood pressure, glucose)
    recorded by the currently authenticated patient.
    """
    try:
        monitor_data_response = supabase.table('patient_monitor_data').select('*').eq('patient_id', patient_profile['id']).execute()
        return monitor_data_response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve monitor data: {str(e)}")

@router.post("/me/monitor-data", summary="Add a new monitor data point for myself")
async def add_own_monitor_data(
    data: MonitorDataCreate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """
    Adds a new health monitor data point (e.g., a glucose reading) for the
    currently authenticated patient.
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
    Updates a specific health monitor data entry belonging to the
    currently authenticated patient.
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

@router.get("/me/daily-logs", summary="Get all my daily logs")
async def get_own_daily_logs(patient_profile: dict = Depends(get_current_patient_profile)):
    """
    Retrieves all daily logs for the currently authenticated patient.
    """
    try:
        logs_response = supabase.table('daily_patient_logs').select('*').eq('patient_id', patient_profile['id']).execute()
        return logs_response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve daily logs: {str(e)}")


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
    Retrieves the set of health thresholds (min/max values for data types)
    defined for the currently authenticated patient.
    """
    try:
        thresholds_response = supabase.table('patient_thresholds').select('*').eq('patient_id', patient_profile['id']).execute()
        return thresholds_response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve thresholds: {str(e)}")
