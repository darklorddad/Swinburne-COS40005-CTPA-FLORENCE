import asyncio
from fastapi import APIRouter, Depends, HTTPException, Header
from pydantic import BaseModel, model_validator, Field
from typing import Optional
from supabase_auth.errors import AuthApiError
from datetime import datetime, date
from enum import Enum

from client import supabase

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
        # We avoid .single() to handle "0 rows" or "multiple rows" manually and safely.
        profile_response = supabase.table('patient_profiles').select('*').eq('user_id', user.id).execute()
        
        if not profile_response.data:
            # Retry once to handle potential race conditions in the client/connection
            await asyncio.sleep(0.1)
            profile_response = supabase.table('patient_profiles').select('*').eq('user_id', user.id).execute()
            
            if not profile_response.data:
                print(f"DEBUG: Access denied for user_id: {user.id}. Profile not found.")
                raise HTTPException(status_code=403, detail="Access denied: User is not a patient.")
        
        if len(profile_response.data) > 1:
            raise HTTPException(status_code=500, detail="Fatal: Multiple profiles found for a single user.")
            
        return profile_response.data[0]
    except AuthApiError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e.message}")
    except HTTPException as e:
        raise e
    except Exception as e:
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
    # Detailed Cholesterol
    CHOLESTEROL_TOTAL = 'CHOLESTEROL_TOTAL'
    CHOLESTEROL_LDL = 'CHOLESTEROL_LDL'
    CHOLESTEROL_HDL = 'CHOLESTEROL_HDL'
    CHOLESTEROL_TRIGLYCERIDES = 'CHOLESTEROL_TRIGLYCERIDES'

class MonitorDataCreate(BaseModel):
    data_type: MonitorDataType
    # Database Foolproofing: Ensure values are physically possible (0 < x < 1000)
    value: float = Field(..., gt=0, lt=1000, description="Must be a positive physiological value")
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
    glucose_before_meal_time: Optional[datetime] = None
    glucose_after_meal_time: Optional[datetime] = None
    meal_desc: Optional[str] = None

    @model_validator(mode='before')
    @classmethod
    def check_at_least_one_entry(cls, values):
        before = values.get('glucose_before_meal')
        after = values.get('glucose_after_meal')
        desc = values.get('meal_desc')
        
        if before is None and after is None and desc is None:
            raise ValueError('You must provide at least a glucose reading OR a meal description.')
        return values

class ActivityLogCreate(BaseModel):
    activity_description: str
    duration_minutes: int
    performed_at: datetime

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


@router.post("/me/daily-logs", summary="Add or Update a daily log for myself")
async def add_own_daily_log(
    log_data: DailyLogCreate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """
    Adds or updates a daily log entry. If a log exists for this date/meal, it updates it.
    """
    try:
        # exclude_unset=True ensures we don't overwrite existing data with None 
        # if the user only sends partial data (e.g. only glucose_after)
        data_dict = log_data.model_dump(mode='json', exclude_unset=True)
        data_dict['patient_id'] = patient_profile['id']
        
        # Check if row exists
        existing = supabase.table('daily_patient_logs')\
            .select('id')\
            .eq('patient_id', patient_profile['id'])\
            .eq('log_date', data_dict['log_date'])\
            .eq('meal_time', data_dict['meal_time'])\
            .execute()

        if existing.data:
            # Update existing row
            log_id = existing.data[0]['id']
            response = supabase.table('daily_patient_logs').update(data_dict).eq('id', log_id).execute()
            return response.data[0]
        else:
            # Insert new row
            response = supabase.table('daily_patient_logs').insert(data_dict).execute()
            return response.data[0]

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save daily log: {str(e)}")


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


@router.get("/me/activity-logs", summary="Get my activity logs")
async def get_own_activity_logs(patient_profile: dict = Depends(get_current_patient_profile)):
    """Retrieves all activity logs."""
    try:
        response = supabase.table('patient_activity_logs').select('*').eq('patient_id', patient_profile['id']).order('performed_at', desc=True).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve activity logs: {str(e)}")

@router.post("/me/activity-logs", summary="Log an activity")
async def add_own_activity_log(
    log_data: ActivityLogCreate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """Logs an activity."""
    try:
        insert_dict = log_data.model_dump(mode='json')
        insert_dict['patient_id'] = patient_profile['id']
        
        response = supabase.table('patient_activity_logs').insert(insert_dict).execute()
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to log activity: {str(e)}")
