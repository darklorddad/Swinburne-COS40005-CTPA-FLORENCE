import asyncio
import os
import httpx
from fastapi import APIRouter, Depends, HTTPException, Header, UploadFile, File, Form, BackgroundTasks
from pydantic import BaseModel, model_validator, Field, EmailStr
from typing import Optional, Literal, List
from supabase_auth.errors import AuthApiError
from datetime import datetime, date, timedelta
from enum import Enum

import time
from client import supabase

# --- Conversion Helpers ---

def convert_glucose_from_base(value: Optional[float], unit: str) -> Optional[float]:
    if value is None: return None
    if unit == 'mg/dL':
        return round(value * 18.0)
    return round(value, 1)

def convert_glucose_to_base(value: Optional[float], unit: str) -> Optional[float]:
    if value is None: return None
    if unit == 'mg/dL':
        return round(value / 18.0, 2)
    return round(value, 2)

def convert_cholesterol_from_base(value: Optional[float], unit: str, is_trig: bool = False) -> Optional[float]:
    if value is None: return None
    if unit == 'mg/dL':
        factor = 88.57 if is_trig else 38.67
        return round(value * factor, 1)
    return round(value, 1)

def convert_cholesterol_to_base(value: Optional[float], unit: str, is_trig: bool = False) -> Optional[float]:
    if value is None: return None
    if unit == 'mg/dL':
        factor = 88.57 if is_trig else 38.67
        return round(value / factor, 2)
    return round(value, 2)

# --- Constants ---

DEFAULT_THRESHOLDS = [
    {'data_type': 'GLUCOSE', 'min_value': 3.9, 'max_value': 10.0},
    {'data_type': 'CHOLESTEROL_TOTAL', 'min_value': 2.6, 'max_value': 5.2},
    {'data_type': 'CHOLESTEROL_LDL', 'min_value': 0.0, 'max_value': 2.6},
    {'data_type': 'CHOLESTEROL_HDL', 'min_value': 1.0, 'max_value': 2.6},
    {'data_type': 'CHOLESTEROL_TRIGLYCERIDES', 'min_value': 0.0, 'max_value': 1.7},
    {'data_type': 'HBA1C', 'min_value': 4.0, 'max_value': 5.7},
    {'data_type': 'BMI', 'min_value': 18.5, 'max_value': 24.9},
    {'data_type': 'BLOOD_PRESSURE_SYSTOLIC', 'min_value': 90.0, 'max_value': 120.0},
    {'data_type': 'BLOOD_PRESSURE_DIASTOLIC', 'min_value': 60.0, 'max_value': 80.0}
]

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
            await asyncio.sleep(0.5)
            profile_response = supabase.table('patient_profiles').select('*').eq('user_id', user.id).execute()
            
            if not profile_response.data:
                # --- AUTO-HEAL: Create missing profile if user is a PATIENT ---
                role = user.app_metadata.get('role', '').upper()
                if role == 'PATIENT':
                    print(f"DEBUG: Auto-creating missing profile for patient {user.id}")
                    try:
                        # Attempt to get name from metadata, fallback to email
                        name = user.user_metadata.get('name', user.email.split('@')[0] if user.email else 'Patient')
                        
                        new_profile = {
                            "user_id": user.id,
                            "name": name,
                            "risk_level": "LOW"
                        }
                        
                        insert_res = supabase.table('patient_profiles').insert(new_profile).execute()
                        if insert_res.data:
                            profile_data = insert_res.data[0]
                            # Insert default thresholds
                            thresholds = [{**t, 'patient_id': profile_data['id']} for t in DEFAULT_THRESHOLDS]
                            supabase.table('patient_thresholds').insert(thresholds).execute()
                            
                            return profile_data
                    except Exception as e:
                        # If creation fails (e.g., Duplicate Key), it implies the profile ALREADY EXISTS.
                        # We must fetch it again immediately instead of failing.
                        print(f"DEBUG: Auto-create clash for {user.id}. Fetching existing profile.")
                        final_attempt = supabase.table('patient_profiles').select('*').eq('user_id', user.id).execute()
                        if final_attempt.data:
                            return final_attempt.data[0]
                        
                        # Only fail if we really can't find it
                        print(f"ERROR: Auto-create failed and fetch failed: {e}")

                # DEBUGGING LOGS FOR 403
                print(f"DEBUG: Access denied for user_id: {user.id}")
                print(f"DEBUG: Role from metadata: {role}")
                print(f"DEBUG: Profile lookup failed even after retry.")
                
                raise HTTPException(status_code=403, detail=f"Access denied: User {user.id} is not a patient.")
        
        if len(profile_response.data) > 1:
            raise HTTPException(status_code=500, detail="Fatal: Multiple profiles found for a single user.")
            
        profile = profile_response.data[0]
        
        # Fetch user settings to include in the profile context for unit conversion
        settings_res = supabase.table("user_settings").select("glucose_unit, cholesterol_unit, show_quick_actions").eq("user_id", user.id).execute()
        if settings_res.data:
            profile['settings'] = settings_res.data[0]
        else:
            profile['settings'] = {"glucose_unit": "mmol/L", "cholesterol_unit": "mmol/L", "show_quick_actions": False}
            
        # Fetch assigned clinician details if any
        if profile.get('clinician_id'):
            clinician_res = supabase.table('clinician_profiles').select('name, organisations(name)').eq('id', profile['clinician_id']).execute()
            if clinician_res.data:
                clinician_data = clinician_res.data[0]
                org_name = clinician_data.get('organisations', {}).get('name') if clinician_data.get('organisations') else None
                profile['clinician'] = {
                    'name': clinician_data.get('name'),
                    'organisation': org_name
                }
            
        return profile
    except AuthApiError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e.message}")
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# --- Pydantic Models ---

class RiskLevelUpdate(BaseModel):
    risk_level: str
    risk_rationale: Optional[str] = None
    daily_insight: Optional[str] = None

class UserSettingsUpdate(BaseModel):
    glucose_unit: Optional[str] = None
    cholesterol_unit: Optional[str] = None
    show_quick_actions: Optional[bool] = None

class UserSettingsResponse(BaseModel):
    glucose_unit: str
    cholesterol_unit: str
    show_quick_actions: bool = False

class PatientProfileUpdate(BaseModel):
    """Fields a patient is allowed to update on their own profile."""
    name: Optional[str] = None
    gender: Optional[str] = None
    date_of_birth: Optional[date] = None
    phone_number: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_relationship: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    profile_picture_url: Optional[str] = None
    email: Optional[EmailStr] = None
    height: Optional[float] = Field(None, gt=0, lt=300)
    weight: Optional[float] = Field(None, gt=0, lt=500)

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
    # Foolproof 3: Database integrity check (must be positive, physiological value)
    value: float = Field(..., gt=0, lt=3000, description="Must be a positive physiological value")
    measured_at: datetime

class MonitorDataUpdate(BaseModel):
    value: Optional[float] = None
    measured_at: Optional[datetime] = None

class DiseaseLogCreate(BaseModel):
    condition_name: str
    status: Literal['active', 'resolved']
    diagnosed_date: Optional[date] = None
    resolved_date: Optional[date] = None
    notes: Optional[str] = None

class DiseaseLogUpdate(BaseModel):
    condition_name: Optional[str] = None
    status: Optional[Literal['active', 'resolved']] = None
    diagnosed_date: Optional[date] = None
    resolved_date: Optional[date] = None
    notes: Optional[str] = None

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
    calories: Optional[int] = None
    photo_url: Optional[str] = None

    @model_validator(mode='before')
    @classmethod
    def check_at_least_one_entry(cls, values):
        before = values.get('glucose_before_meal')
        after = values.get('glucose_after_meal')
        desc = values.get('meal_desc')
        calories = values.get('calories')
        photo = values.get('photo_url')
        
        if before is None and after is None and desc is None and calories is None and photo is None:
            raise ValueError('You must provide at least a glucose reading, meal description, calories, or photo.')
        return values

class ActivityLogCreate(BaseModel):
    activity_description: str
    active_duration_minutes: int
    start_time: datetime
    end_time: datetime
    calories_burned: Optional[int] = None

class MedicationCreate(BaseModel):
    medication_id: Optional[int] = None
    custom_medication_name: Optional[str] = None
    frequency_id: int
    amount: str
    medication_type: Optional[str] = None
    timing_instructions: List[str] = ["ANYTIME"]
    notes: Optional[str] = None

class PatientMedicationUpdate(BaseModel):
    """Fields allowed for partial updates on patient medications."""
    medication_id: Optional[int] = None
    custom_medication_name: Optional[str] = None
    frequency_id: Optional[int] = None
    amount: Optional[str] = None
    medication_type: Optional[str] = None
    timing_instructions: Optional[List[str]] = None
    status: Optional[str] = None

class MedicationIntakeCreate(BaseModel):
    patient_medication_id: int
    status: Literal['TAKEN', 'SKIPPED', 'LATE'] = 'TAKEN'
    taken_at: Optional[datetime] = None
    notes: Optional[str] = None

class ThresholdUpdateItem(BaseModel):
    data_type: str
    min_value: float
    max_value: float

    @model_validator(mode='after')
    def validate_clinical_ranges(self):
        # 1. Logical Sanity Check
        if self.min_value >= self.max_value:
            raise ValueError(f"Min value ({self.min_value}) must be less than Max value ({self.max_value}) for {self.data_type}.")

        # 2. Biological Absolute Limits (Format: Min, Max)
        # These assume BASE units: mmol/L, mmHg, kg/m2, %
        # 2. Biological Absolute Limits (Format: Min, Max)
        # These bounds accommodate BOTH mmol/L and mg/dL to pass initial Pydantic validation
        absolute_limits = {
            'BLOOD_PRESSURE_SYSTOLIC': (50.0, 300.0),  
            'BLOOD_PRESSURE_DIASTOLIC': (30.0, 200.0), 
            'GLUCOSE': (1.5, 1000.0),                  # Accommodates up to 1000 mg/dL
            'BMI': (10.0, 150.0),                      
            'HBA1C': (3.0, 30.0),                      
            'CHOLESTEROL_TOTAL': (0.0, 1500.0),
            'CHOLESTEROL_LDL': (0.0, 1500.0),          
            'CHOLESTEROL_HDL': (0.0, 500.0),
            'CHOLESTEROL_TRIGLYCERIDES': (0.0, 3000.0),
        }

        # 3. Apply the Limits
        limits = absolute_limits.get(self.data_type)
        if limits:
            abs_min, abs_max = limits

            # Check if the user's MIN target is dangerously low
            if self.min_value < abs_min:
                raise ValueError(
                    f"Target minimum of {self.min_value} is dangerously low for {self.data_type}. "
                    f"Absolute allowed minimum is {abs_min}."
                )

            # Check if the user's MAX target is dangerously high
            if self.max_value > abs_max:
                raise ValueError(
                    f"Target maximum of {self.max_value} is dangerously high for {self.data_type}. "
                    f"Absolute allowed maximum is {abs_max}."
                )

        return self

class ThresholdUpdateBatch(BaseModel):
    thresholds: List[ThresholdUpdateItem]

class ClinicalDocumentCreate(BaseModel):
    patient_id: int
    document_path: str
    document_type: str

class AutomatedActionCreate(BaseModel):
    type: str
    description: str
    response: Optional[str] = None

class RecommendationCreate(BaseModel):
    id: str
    timeframe: Literal['daily', 'weekly']
    category: str
    title: str
    description: str
    priority: str
    status: str = 'active'
    generated_at: datetime
    expires_at: Optional[datetime] = None
    action_items: List[str] = []
    explanation: Optional[dict] = None
    data_sources: Optional[dict] = None

class RecommendationBatchCreate(BaseModel):
    timeframe: Optional[str] = None
    recommendations: List[RecommendationCreate]

class RecommendationUpdate(BaseModel):
    status: Literal['active', 'completed', 'dismissed']

# --- Router Definition ---

router = APIRouter(
    prefix="/patients",
    tags=["Patient (Self-Service)"]
)

@router.get("/me/settings", response_model=UserSettingsResponse, summary="Get my app settings")
async def get_user_settings(patient_profile: dict = Depends(get_current_patient_profile)):
    """
    Retrieves the app settings (units of measurement) for the authenticated patient.
    """
    try:
        response = supabase.table("user_settings").select("glucose_unit, cholesterol_unit, show_quick_actions").eq("user_id", patient_profile['user_id']).execute()
        
        if not response.data:
            # Return defaults if no settings record exists yet
            return {"glucose_unit": "mmol/L", "cholesterol_unit": "mmol/L", "show_quick_actions": False}
            
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch settings: {str(e)}")

@router.patch("/me/settings", summary="Update my app settings")
async def update_user_settings(
    settings: UserSettingsUpdate, 
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """
    Updates app settings like measurement units.
    """
    update_data = settings.model_dump(exclude_unset=True)
    if not update_data:
        return {"message": "No fields to update"}
        
    try:
        # Use upsert to handle cases where the settings row might not exist yet
        update_data["user_id"] = patient_profile['user_id']
        supabase.table("user_settings").upsert(update_data).execute()
        return {"message": "Settings updated successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update settings: {str(e)}")

@router.get("/me", summary="Get my own full patient profile")
async def get_own_patient_profile(patient_profile: dict = Depends(get_current_patient_profile)):
    """
    Retrieves the complete profile for the currently authenticated patient.
    Generates a fresh signed URL for the profile picture if it exists.
    """
    avatar_path = patient_profile.get('profile_picture_url')
    if avatar_path:
        try:
            # Generate a signed URL valid for 1 hour
            res = supabase.storage.from_("Bucket").create_signed_url(avatar_path, 3600)
            # The response from Supabase Python client for create_signed_url is usually the URL string or a dict
            signed_url = res if isinstance(res, str) else res.get('signedURL')
            patient_profile['profile_picture_url'] = signed_url
        except Exception as e:
            print(f"DEBUG: Failed to sign avatar URL: {e}")

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
        # Handle email update separately via Auth Admin API
        if 'email' in update_dict:
            new_email = update_dict.pop('email')
            # Update email in Supabase Auth
            supabase.auth.admin.update_user_by_id(
                patient_profile['user_id'], 
                {"email": new_email}
            )
        
        # If there are other fields to update in the profile table
        if update_dict:
            # Ensure date conversion for JSON serialization if needed
            if 'date_of_birth' in update_dict and update_dict['date_of_birth']:
                update_dict['date_of_birth'] = update_dict['date_of_birth'].isoformat()

            updated_profile_response = supabase.table('patient_profiles').update(update_dict).eq('id', patient_profile['id']).execute()
            profile_data = updated_profile_response.data[0]

            # --- AUTO-LOG BMI: If height or weight changed, log a new BMI entry ---
            if 'height' in update_dict or 'weight' in update_dict:
                h = profile_data.get('height')
                w = profile_data.get('weight')
                if h and w and h > 0:
                    bmi = w / ((h / 100) ** 2)
                    supabase.table('patient_monitor_data').insert({
                        'patient_id': patient_profile['id'],
                        'data_type': 'BMI',
                        'value': round(bmi, 2),
                        'measured_at': datetime.now().isoformat()
                    }).execute()

            return profile_data
        else:
            # Return existing profile if only email was updated
            return patient_profile
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update profile: {str(e)}")

@router.patch("/me/risk", summary="Update my own risk level and rationale")
async def update_own_risk(
    update_data: RiskLevelUpdate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """Updates the risk level and rationale for the authenticated patient."""
    try:
        update_dict = update_data.model_dump(exclude_unset=True)
        update_dict['last_risk_assessment'] = datetime.now().isoformat()
        
        # Safe update: auto-recovers if the SQL column hasn't been added yet
        try:
            response = supabase.table('patient_profiles').update(update_dict).eq('id', patient_profile['id']).execute()
            return response.data[0]
        except Exception as inner_e:
            if "daily_insight" in str(inner_e):
                update_dict.pop("daily_insight", None)
                response = supabase.table('patient_profiles').update(update_dict).eq('id', patient_profile['id']).execute()
                return response.data[0]
            raise inner_e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update risk: {str(e)}")

@router.get("/me/monitor-data", summary="Get all my monitor data")
async def get_own_monitor_data(
    limit: Optional[int] = None,
    offset: int = 0,
    order: str = 'measured_at.desc',
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """
    Retrieves health monitor data (e.g., blood pressure, glucose)
    recorded by the currently authenticated patient with pagination support.
    """
    try:
        query = supabase.table('patient_monitor_data').select('*').eq('patient_id', patient_profile['id'])
        
        if order:
            parts = order.split('.')
            col = parts[0]
            desc = True if len(parts) > 1 and parts[1] == 'desc' else False
            query = query.order(col, desc=desc)
            
        if limit is not None:
            query = query.range(offset, offset + limit - 1)
            
        monitor_data_response = query.execute()
        data = monitor_data_response.data
        
        # Convert units based on user preference
        g_unit = patient_profile['settings']['glucose_unit']
        c_unit = patient_profile['settings']['cholesterol_unit']
        
        for item in data:
            if item['data_type'] == 'GLUCOSE':
                item['value'] = convert_glucose_from_base(item['value'], g_unit)
            elif 'CHOLESTEROL' in item['data_type']:
                is_trig = (item['data_type'] == 'CHOLESTEROL_TRIGLYCERIDES')
                item['value'] = convert_cholesterol_from_base(item['value'], c_unit, is_trig)
                
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve monitor data: {str(e)}")

@router.post("/me/clinical-documents", summary="Create a clinical document record")
async def create_clinical_document(
    doc_data: ClinicalDocumentCreate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """
    Inserts a record into the clinical_documents table.
    """
    try:
        # Ensure we use the patient_id from the authenticated profile for security
        payload = {
            "patient_id": patient_profile['id'],
            "document_path": doc_data.document_path,
            "document_type": doc_data.document_type
        }
        
        result = supabase.table("clinical_documents").insert(payload).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create document record")

        return result.data[0]
    except Exception as e:
        print(f"ERROR: create_clinical_document: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/me/automated-actions", summary="Log an automated action for myself")
async def log_own_automated_action(
    action: AutomatedActionCreate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """Logs an automated action triggered by the patient's device."""
    try:
        payload = action.model_dump(exclude_unset=True)
        payload['patient_id'] = patient_profile['id']
        
        response = supabase.table('automated_actions').insert(payload).execute()
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to log automated action: {str(e)}")

@router.post("/me/monitor-data", summary="Add a new monitor data point for myself")
async def add_own_monitor_data(
    data: MonitorDataCreate,
    background_tasks: BackgroundTasks,
    authorization: str = Header(...),
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """
    Adds a new health monitor data point (e.g., a glucose reading) for the
    currently authenticated patient.
    """
    insert_dict = data.model_dump(mode='json')
    insert_dict['patient_id'] = patient_profile['id']
    
    # Convert to base unit before saving
    if data.data_type == MonitorDataType.GLUCOSE:
        insert_dict['value'] = convert_glucose_to_base(data.value, patient_profile['settings']['glucose_unit'])
    elif 'CHOLESTEROL' in data.data_type:
        is_trig = (data.data_type == 'CHOLESTEROL_TRIGLYCERIDES')
        insert_dict['value'] = convert_cholesterol_to_base(data.value, patient_profile['settings']['cholesterol_unit'], is_trig)
        
    try:
        new_data_response = supabase.table('patient_monitor_data').insert(insert_dict).execute()
        
        async def trigger_risk_assessment():
            pass # Disabled: Handled securely by the Unified Daily Pipeline now.
        
        background_tasks.add_task(trigger_risk_assessment)
        
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

@router.get("/me/disease-logs", summary="Get my disease logs")
async def get_own_disease_logs(patient_profile: dict = Depends(get_current_patient_profile)):
    try:
        response = supabase.table('disease_logs').select('*').eq('patient_id', patient_profile['id']).order('diagnosed_date', desc=True).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/me/disease-logs", summary="Add a disease log")
async def add_own_disease_log(
    log_data: DiseaseLogCreate, 
    patient_profile: dict = Depends(get_current_patient_profile)
):
    try:
        insert_dict = log_data.model_dump(mode='json')
        insert_dict['patient_id'] = patient_profile['id']
        
        # Logic: If status is active, ensure resolved_date is null
        if log_data.status == 'active':
            insert_dict['resolved_date'] = None
            
        response = supabase.table('disease_logs').insert(insert_dict).execute()
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save disease log: {str(e)}")

@router.patch("/me/disease-logs/{log_id}", summary="Update a disease log")
async def update_own_disease_log(
    log_id: int,
    log_update: DiseaseLogUpdate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    try:
        update_dict = log_update.model_dump(mode='json', exclude_unset=True)
        if not update_dict:
            raise HTTPException(status_code=400, detail="No fields provided for update")

        # Logic: If changing to active, wipe the resolved date
        if update_dict.get('status') == 'active':
            update_dict['resolved_date'] = None

        response = supabase.table('disease_logs') \
            .update(update_dict) \
            .eq('id', log_id) \
            .eq('patient_id', patient_profile['id']) \
            .execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="Disease log not found")
            
        return response.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update disease log: {str(e)}")

@router.get("/me/daily-logs", summary="Get all my daily logs")
async def get_own_daily_logs(patient_profile: dict = Depends(get_current_patient_profile)):
    """
    Retrieves all daily logs for the currently authenticated patient.
    """
    try:
        logs_response = supabase.table('daily_patient_logs').select('*').eq('patient_id', patient_profile['id']).execute()
        data = logs_response.data
        
        g_unit = patient_profile['settings']['glucose_unit']
        for log in data:
            log['glucose_before_meal'] = convert_glucose_from_base(log.get('glucose_before_meal'), g_unit)
            log['glucose_after_meal'] = convert_glucose_from_base(log.get('glucose_after_meal'), g_unit)
            
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve daily logs: {str(e)}")


@router.post("/me/daily-logs", summary="Add or Update a daily log for myself")
async def add_own_daily_log(
    log_data: DailyLogCreate,
    background_tasks: BackgroundTasks,
    authorization: str = Header(...),
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
        
        g_unit = patient_profile['settings']['glucose_unit']
        if 'glucose_before_meal' in data_dict:
            data_dict['glucose_before_meal'] = convert_glucose_to_base(data_dict['glucose_before_meal'], g_unit)
        if 'glucose_after_meal' in data_dict:
            data_dict['glucose_after_meal'] = convert_glucose_to_base(data_dict['glucose_after_meal'], g_unit)
        
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
            result_data = response.data[0]
        else:
            # Insert new row
            response = supabase.table('daily_patient_logs').insert(data_dict).execute()
            result_data = response.data[0]

        async def trigger_risk_assessment():
            pass # Disabled: Handled securely by the Unified Daily Pipeline now.
        
        background_tasks.add_task(trigger_risk_assessment)

        return result_data

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
        data = thresholds_response.data
        
        g_unit = patient_profile['settings']['glucose_unit']
        c_unit = patient_profile['settings']['cholesterol_unit']

        for t in data:
            if t['data_type'] == 'GLUCOSE':
                t['min_value'] = convert_glucose_from_base(t['min_value'], g_unit)
                t['max_value'] = convert_glucose_from_base(t['max_value'], g_unit)
            elif 'CHOLESTEROL' in t['data_type']:
                is_trig = (t['data_type'] == 'CHOLESTEROL_TRIGLYCERIDES')
                t['min_value'] = convert_cholesterol_from_base(t['min_value'], c_unit, is_trig)
                t['max_value'] = convert_cholesterol_from_base(t['max_value'], c_unit, is_trig)
                
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve thresholds: {str(e)}")


@router.put("/me/thresholds", summary="Update my health thresholds")
async def update_own_thresholds(
    data: ThresholdUpdateBatch,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """Updates multiple thresholds at once, converting from user units back to base mmol/L"""
    patient_id = patient_profile['id']
    g_unit = patient_profile['settings']['glucose_unit']
    c_unit = patient_profile['settings']['cholesterol_unit']

    try:
        for t in data.thresholds:
            min_val = t.min_value
            max_val = t.max_value
            
            if t.data_type == 'GLUCOSE':
                min_val = convert_glucose_to_base(min_val, g_unit)
                max_val = convert_glucose_to_base(max_val, g_unit)
            elif 'CHOLESTEROL' in t.data_type:
                is_trig = (t.data_type == 'CHOLESTEROL_TRIGLYCERIDES')
                min_val = convert_cholesterol_to_base(min_val, c_unit, is_trig)
                max_val = convert_cholesterol_to_base(max_val, c_unit, is_trig)

            supabase.table('patient_thresholds').update({
                'min_value': min_val,
                'max_value': max_val
            }).eq('patient_id', patient_id).eq('data_type', t.data_type).execute()

        return {"message": "Thresholds updated successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update thresholds: {str(e)}")


@router.get("/me/activity-logs", summary="Get my activity logs")
async def get_own_activity_logs(patient_profile: dict = Depends(get_current_patient_profile)):
    """Retrieves all activity logs."""
    try:
        # Use aliasing to match the frontend model keys
        response = supabase.table('patient_activity_logs') \
            .select('*, performed_at:start_time, duration_minutes:active_duration_minutes') \
            .eq('patient_id', patient_profile['id']) \
            .order('start_time', desc=True) \
            .execute()
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

@router.get("/me/medications", summary="Get my medications")
async def get_own_medications(patient_profile: dict = Depends(get_current_patient_profile)):
    """
    Fetches all records from patient_medications for the authenticated patient.
    Includes joined details from medication_dictionary and dosage_frequencies.
    """
    try:
        response = supabase.table('patient_medications').select(
            "*, medication_dictionary(brand_name, generic_name), dosage_frequencies(patient_text)"
        ).eq('patient_id', patient_profile['id']).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve medications: {str(e)}")

@router.post("/me/medications", summary="Add a medication to my profile")
async def add_own_medication(
    data: MedicationCreate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """Inserts a new row into patient_medications for the authenticated patient."""
    if not data.medication_id and not data.custom_medication_name:
        raise HTTPException(status_code=400, detail="Must provide either medication_id or custom_medication_name")

    insert_dict = data.model_dump(mode='json')
    insert_dict['patient_id'] = patient_profile['id']
    try:
        response = supabase.table('patient_medications').insert(insert_dict).execute()
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add medication: {str(e)}")

@router.patch("/me/medications/{med_id}", summary="Update a medication entry")
async def update_patient_medication(
    med_id: int, 
    med_update: PatientMedicationUpdate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """Updates a specific medication entry for the authenticated patient."""
    try:
        update_data = med_update.model_dump(exclude_unset=True)
        if not update_data:
             raise HTTPException(status_code=400, detail="No fields provided for update")

        # --- THE FIX: ENFORCE THE CONSTRAINT BEFORE SUPABASE ---
        # If they are saving a Custom Medication, wipe the Dictionary ID
        if 'custom_medication_name' in update_data and update_data['custom_medication_name'] is not None:
            update_data['medication_id'] = None
            
        # If they are saving a Dictionary Medication, wipe the Custom Name
        elif 'medication_id' in update_data and update_data['medication_id'] is not None:
            update_data['custom_medication_name'] = None
        # -------------------------------------------------------

        response = supabase.table("patient_medications") \
            .update(update_data) \
            .eq("id", med_id) \
            .eq("patient_id", patient_profile['id']) \
            .execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="Medication not found or access denied")
            
        return response.data[0]
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@router.get("/me/medication-schedule", summary="Get medication schedule and logs for a date")
async def get_medication_schedule(
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """
    Fetches active medications and intake logs.
    Calculates log counts based on daily/weekly frequency.
    """
    try:
        # 1. Date calculations
        today_str = datetime.now().strftime("%Y-%m-%d")
        week_ago_str = (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d")

        # 2. Fetch active medications
        meds_res = supabase.table("patient_medications") \
            .select("*, medication_dictionary(*), dosage_frequencies(*)") \
            .eq("patient_id", patient_profile['id']) \
            .eq("status", "CURRENT") \
            .execute()
        meds = meds_res.data

        # 3. Fetch intake logs for the last 7 days
        logs_res = supabase.table("medication_intake_logs") \
            .select("*") \
            .eq("patient_id", patient_profile['id']) \
            .gte("taken_at", f"{week_ago_str}T00:00:00") \
            .lte("taken_at", f"{today_str}T23:59:59") \
            .execute()
        logs = logs_res.data

        # 4. Map the logs to the medications
        schedule = []
        for med in meds:
            # Safely check frequency text for "week"
            freq = med.get("dosage_frequencies") or {}
            patient_text = (freq.get("patient_text") or "").lower()
            is_weekly = "week" in patient_text

            # Filter logs specific to this medication
            med_logs = [l for l in logs if l["patient_medication_id"] == med["id"]]
            
            if is_weekly:
                # For weekly, count any log in the last 7 days
                times_logged = len(med_logs)
            else:
                # For daily, count only logs from TODAY
                times_logged = len([l for l in med_logs if l["taken_at"].startswith(today_str)])

            schedule.append({
                "medication": med,
                "times_logged": times_logged,
                "is_weekly": is_weekly
            })

        return schedule
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve medication schedule: {str(e)}")

@router.post("/me/medication-intake", summary="Log a medication intake event")
async def log_medication_intake(
    data: MedicationIntakeCreate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """Records a medication intake event. Defaults taken_at to current UTC if not provided."""
    insert_dict = data.model_dump(mode='json')
    insert_dict['patient_id'] = patient_profile['id']
    
    if insert_dict.get('taken_at') is None:
        insert_dict['taken_at'] = datetime.now().isoformat()
        
    try:
        response = supabase.table('medication_intake_logs').insert(insert_dict).execute()
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to log medication intake: {str(e)}")

@router.delete("/me/medication-intake/{patient_medication_id}", summary="Unlog today's medication intake")
async def unlog_medication(
    patient_medication_id: int,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """Deletes the medication intake log for the specified medication created today."""
    try:
        today = date.today().isoformat()
        
        # Query Supabase for a log for this med, on this day, for this patient
        response = supabase.table("medication_intake_logs") \
            .delete() \
            .eq("patient_id", patient_profile['id']) \
            .eq("patient_medication_id", patient_medication_id) \
            .gte("taken_at", f"{today}T00:00:00") \
            .lte("taken_at", f"{today}T23:59:59") \
            .execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="No log found for today to delete")
            
        return {"status": "success", "message": "Log removed"}
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/me/avatar", summary="Upload profile picture")
async def upload_patient_avatar(
    file: UploadFile = File(...),
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """Uploads a profile picture to Storage and updates the profile record."""
    try:
        user_id = patient_profile['user_id']
        
        # 0. Clean up old avatars
        try:
            folder_path = f"Profile_Picture/{user_id}"
            # List files in the user's folder to delete previous ones
            existing_files = supabase.storage.from_("Bucket").list(folder_path)
            
            if existing_files:
                files_to_remove = [f"{folder_path}/{f['name']}" for f in existing_files if 'name' in f]
                if files_to_remove:
                    supabase.storage.from_("Bucket").remove(files_to_remove)
        except Exception as cleanup_error:
            # Continue even if cleanup fails
            print(f"Warning: Failed to cleanup old avatars: {cleanup_error}")

        file_ext = file.filename.split('.')[-1]
        
        # Sanitize username for filename (Requirement: save as username.extension)
        raw_name = patient_profile.get('name', 'user').strip()
        # Keep alphanumeric, dashes, underscores. Replace others with underscore.
        safe_name = "".join([c if c.isalnum() or c in ('-', '_') else '_' for c in raw_name])
        # Remove consecutive underscores
        while "__" in safe_name:
            safe_name = safe_name.replace("__", "_")
        
        if not safe_name:
            safe_name = "user"

        # Create filename: Profile_Picture/{user_id}/{username}.{ext}
        filename = f"Profile_Picture/{user_id}/{safe_name}.{file_ext}"
        
        file_content = await file.read()

        # 1. Upload to Supabase Storage
        supabase.storage.from_("Bucket").upload(
            file=file_content,
            path=filename,
            file_options={"content-type": file.content_type, "upsert": "true"}
        )

        # 2. Update Database Profile with the PATH, not the URL
        supabase.table('patient_profiles').update({
            "profile_picture_url": filename
        }).eq('id', patient_profile['id']).execute()

        # 3. Return a signed URL for immediate UI update
        res = supabase.storage.from_("Bucket").create_signed_url(filename, 3600)
        return {"url": res.get('signedURL'), "path": filename}

    except Exception as e:
        print(f"Upload Error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to upload image: {str(e)}")

@router.post("/me/clinical-documents/upload", summary="Upload and record a clinical document")
async def upload_clinical_document(
    file: UploadFile = File(...),
    document_type: str = Form(...),
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """
    Uploads a file to the clinical-documents bucket and creates a DB record.
    Returns the record including the generated ID and storage path.
    """
    try:
        user_id = patient_profile['user_id']
        filename_parts = file.filename.split('.')
        file_ext = filename_parts[-1] if len(filename_parts) > 1 else "bin"
        timestamp = int(time.time())
        
        # Path: {user_id}/{doc_type}/{timestamp}.{ext}
        folder = document_type.lower().replace(" ", "_")
        storage_path = f"{user_id}/{folder}/{timestamp}.{file_ext}"
        
        file_content = await file.read()

        # 1. Upload to Storage
        supabase.storage.from_("clinical-documents").upload(
            file=file_content,
            path=storage_path,
            file_options={"content-type": file.content_type or "application/octet-stream", "upsert": "true"}
        )

        # 2. Create DB Record
        result = supabase.table("clinical_documents").insert({
            "patient_id": patient_profile['id'],
            "document_path": storage_path,
            "document_type": document_type
        }).execute()

        if not result.data:
            raise Exception("Failed to insert document record into database")

        return result.data[0]

    except Exception as e:
        print(f"ERROR: upload_clinical_document: {e}")
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")


@router.post("/me/meal-photo", summary="Upload meal photo")
async def upload_meal_photo(
    file: UploadFile = File(...),
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """Uploads a meal photo to Storage."""
    try:
        user_id = patient_profile['user_id']
        file_ext = file.filename.split('.')[-1]
        
        # Create filename: Meal_Photos/{user_id}/{timestamp}.{ext}
        filename = f"Meal_Photos/{user_id}/{int(time.time())}.{file_ext}"
        
        file_content = await file.read()

        # 1. Upload to Supabase Storage
        res = supabase.storage.from_("Bucket").upload(
            file=file_content,
            path=filename,
            file_options={"content-type": file.content_type, "upsert": "true"}
        )

        # 2. Get Public URL
        public_url = supabase.storage.from_("Bucket").get_public_url(filename)

        return {"url": public_url}

    except Exception as e:
        print(f"Upload Error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to upload image: {str(e)}")

# --- Recommendation Endpoints ---

@router.get("/me/recommendations", summary="Get my recommendations")
async def get_own_recommendations(patient_profile: dict = Depends(get_current_patient_profile)):
    """Retrieves all recommendations (daily and weekly) for the patient."""
    try:
        response = supabase.table('patient_recommendations') \
            .select('*') \
            .eq('patient_id', patient_profile['id']) \
            .order('generated_at', desc=True) \
            .execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve recommendations: {str(e)}")

@router.post("/me/recommendations", summary="Save new recommendations in bulk")
async def save_recommendations(
    data: RecommendationBatchCreate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """Saves a batch of LLM-generated recommendations to the database."""
    try:
        # 1. Determine which timeframe we are replacing
        if data.timeframe:
            timeframes = [data.timeframe]
        else:
            timeframes = list(set([rec.timeframe for rec in data.recommendations]))
            
        # 2. Automatically dismiss old active recommendations for this timeframe
        for tf in timeframes:
            supabase.table('patient_recommendations') \
                .update({'status': 'dismissed'}) \
                .eq('patient_id', patient_profile['id']) \
                .eq('timeframe', tf) \
                .eq('status', 'active') \
                .execute()

        # 3. Insert the newly generated recommendations
        insert_data = []
        for rec in data.recommendations:
            rec_dict = rec.model_dump(mode='json', exclude={'timeframe'})
            rec_dict['timeframe'] = rec.timeframe # ensure it's in the dict
            rec_dict['patient_id'] = patient_profile['id']
            insert_data.append(rec_dict)
        
        if insert_data:
            response = supabase.table('patient_recommendations').upsert(insert_data).execute()
            return response.data
        return []
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save recommendations: {str(e)}")

@router.patch("/me/recommendations/{rec_id}", summary="Update recommendation status")
async def update_recommendation_status(
    rec_id: str,
    update_data: RecommendationUpdate,
    patient_profile: dict = Depends(get_current_patient_profile)
):
    """Marks a recommendation as completed or dismissed."""
    try:
        response = supabase.table('patient_recommendations') \
            .update({'status': update_data.status}) \
            .eq('id', rec_id) \
            .eq('patient_id', patient_profile['id']) \
            .execute()
        
        if not response.data:
            raise HTTPException(status_code=404, detail="Recommendation not found or access denied")
            
        return response.data[0]
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update recommendation: {str(e)}")

# --- Global Medication Endpoints ---

@router.get("/medications/dictionary", summary="Get global medication dictionary")
async def get_medication_dictionary():
    """Retrieves all verified medications from the global dictionary."""
    try:
        response = supabase.table("medication_dictionary").select("*").order("brand_name").execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/medications/frequencies", summary="Get available dosage frequencies")
async def get_dosage_frequencies():
    """Retrieves all available dosage frequencies."""
    try:
        response = supabase.table("dosage_frequencies").select("*").execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
