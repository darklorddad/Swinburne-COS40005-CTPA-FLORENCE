import asyncio
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
        # We avoid .single() to handle "0 rows" or "multiple rows" manually and safely.
        profile_response = supabase.table('clinician_profiles').select('*').eq('user_id', user.id).execute()
        
        if not profile_response.data:
            # Retry once to handle potential race conditions
            await asyncio.sleep(0.1)
            profile_response = supabase.table('clinician_profiles').select('*').eq('user_id', user.id).execute()

            if not profile_response.data:
                raise HTTPException(status_code=403, detail="Access denied: User is not a clinician.")
            
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

class ClinicianProfileUpdate(BaseModel):
    name: Optional[str] = None
    phone_number: Optional[str] = None
    gender: Optional[str] = None

class PatientProfileUpdate(BaseModel):
    name: Optional[str] = None
    phone_number: Optional[str] = None
    gender: Optional[str] = None
    risk_level: Optional[RiskLevel] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_relationship: Optional[str] = None
    emergency_contact_phone: Optional[str] = None

# --- MEDICAL CONDITIONS (DISEASE) SCHEMAS ---
class DiseaseCreate(BaseModel):
    condition_name: str
    status: str  # 'active' or 'resolved'
    diagnosed_date: str

class DiseaseUpdate(BaseModel):
    condition_name: Optional[str] = None
    status: Optional[str] = None
    diagnosed_date: Optional[str] = None

# --- MEDICATION SCHEMAS ---
class ClinicianMedicationPayload(BaseModel):
    medication_id: Optional[int] = None
    custom_medication_name: Optional[str] = None
    amount: str
    medication_type: str
    frequency_id: int
    timing_instructions: List[str]
    status: str = "CURRENT"

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

@router.put("/me", summary="Update my clinician profile")
async def update_own_clinician_profile(
    update_data: ClinicianProfileUpdate,
    clinician_profile: dict = Depends(get_current_clinician_profile)
):
    """Updates the authenticated clinician's profile."""
    update_dict = update_data.model_dump(exclude_unset=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No update data provided.")

    try:
        updated_profile = supabase.table('clinician_profiles').update(update_dict).eq('id', clinician_profile['id']).execute()
        return updated_profile.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update profile: {str(e)}")

@router.get("/medications/dictionary", summary="Get medication dictionary for autocomplete")
async def get_clinician_medication_dictionary(clinician_profile: dict = Depends(get_current_clinician_profile)):
    """Retrieves the global medication dictionary for clinicians."""
    try:
        res = supabase.table('medication_dictionary').select('*').order('brand_name').execute()
        return res.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch medication dictionary: {str(e)}")

@router.get("/medications/frequencies", summary="Get dosage frequency options")
async def get_clinician_dosage_frequencies(clinician_profile: dict = Depends(get_current_clinician_profile)):
    """Retrieves the global dosage frequencies for clinicians."""
    try:
        res = supabase.table('dosage_frequencies').select('*').execute()
        return res.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch dosage frequencies: {str(e)}")

@router.get("/me/settings", summary="Get my clinician unit settings")
async def get_clinician_settings(clinician_profile: dict = Depends(get_current_clinician_profile)):
    """Retrieves the unit settings for the authenticated clinician."""
    try:
        res = supabase.table('user_settings').select('*').eq('user_id', clinician_profile['user_id']).execute()
        if not res.data:
            return {"glucose_unit": "mmol/L", "cholesterol_unit": "mmol/L"}
        return res.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch settings: {str(e)}")

@router.put("/me/settings", summary="Update my clinician unit settings")
async def update_clinician_settings(
    settings_data: dict,
    clinician_profile: dict = Depends(get_current_clinician_profile)
):
    """Updates or creates the unit settings for the authenticated clinician."""
    try:
        res = supabase.table('user_settings').upsert({
            'user_id': clinician_profile['user_id'],
            'glucose_unit': settings_data.get('glucose_unit', 'mmol/L'),
            'cholesterol_unit': settings_data.get('cholesterol_unit', 'mmol/L'),
            'updated_at': 'now()'
        }).execute()
        return res.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update settings: {str(e)}")

# =========================================================================
# MEDICAL CONDITIONS (DISEASES) MANAGEMENT
# =========================================================================

@router.post("/patients/{patient_id}/diseases", status_code=status.HTTP_201_CREATED)
async def add_patient_disease(
    patient_id: str, 
    payload: DiseaseCreate, 
    clinician_profile: dict = Depends(get_current_clinician_profile)
):
    """Allows a clinician to log a brand new medical diagnosis for a specific patient."""
    try:
        db_payload = {
            "patient_id": patient_id,
            "condition_name": payload.condition_name,
            "status": payload.status.lower(),
            "diagnosed_date": payload.diagnosed_date
        }
        res = supabase.table("disease_logs").insert(db_payload).execute()
        return {"status": "success", "data": res.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to append disease record: {str(e)}")


@router.put("/diseases/{disease_id}")
async def update_patient_disease(
    disease_id: int, 
    payload: DiseaseUpdate, 
    clinician_profile: dict = Depends(get_current_clinician_profile)
):
    """Updates an existing condition record."""
    try:
        update_data = {k: v for k, v in payload.model_dump(exclude_unset=True).items() if v is not None}
        if "status" in update_data:
            update_data["status"] = update_data["status"].lower()

        res = supabase.table("disease_logs").update(update_data).eq("id", disease_id).execute()
        return {"status": "success", "data": res.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to modify disease log: {str(e)}")


@router.delete("/diseases/{disease_id}")
async def remove_patient_disease(
    disease_id: int, 
    clinician_profile: dict = Depends(get_current_clinician_profile)
):
    """Permanently purges a medical condition record."""
    try:
        supabase.table("disease_logs").delete().eq("id", disease_id).execute()
        return {"status": "success", "detail": f"Condition record {disease_id} dropped successfully."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to purge record entry: {str(e)}")

# =========================================================================
# CLINICAL MEDICATION MANAGEMENT
# =========================================================================

@router.post("/patients/{patient_id}/medications", status_code=status.HTTP_201_CREATED)
async def add_patient_medication(
    patient_id: str, 
    payload: ClinicianMedicationPayload, 
    clinician_profile: dict = Depends(get_current_clinician_profile)
):
    """Assigns an entirely new active medical schedule profile to a patient."""
    try:
        db_payload = {
            "patient_id": patient_id,
            "medication_id": payload.medication_id,
            "custom_medication_name": payload.custom_medication_name,
            "amount": payload.amount,
            "medication_type": payload.medication_type,
            "frequency_id": payload.frequency_id,
            "timing_instructions": payload.timing_instructions,
            "status": payload.status.upper()
        }
        res = supabase.table("patient_medications").insert(db_payload).execute()
        return {"status": "success", "data": res.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to insert medication entry: {str(e)}")


@router.put("/medications/{medication_id}")
async def update_patient_medication(
    medication_id: int, 
    payload: ClinicianMedicationPayload, 
    clinician_profile: dict = Depends(get_current_clinician_profile)
):
    """Updates dose, type form layout definitions or frequency schedules for a medication."""
    try:
        update_data = {k: v for k, v in payload.model_dump(exclude_unset=True).items() if v is not None}
        if "status" in update_data:
            update_data["status"] = update_data["status"].upper()

        res = supabase.table("patient_medications").update(update_data).eq("id", medication_id).execute()
        return {"status": "success", "data": res.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save schedule changes: {str(e)}")


@router.delete("/medications/{medication_id}")
async def remove_patient_medication(
    medication_id: int, 
    clinician_profile: dict = Depends(get_current_clinician_profile)
):
    """Discards a medication entry permanently."""
    try:
        supabase.table("patient_medications").delete().eq("id", medication_id).execute()
        return {"status": "success", "detail": f"Medication entry {medication_id} dropped successfully."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to clear target medication from database: {str(e)}")

@router.get("/me/patients", summary="Get a list of all patients assigned to me")
async def get_assigned_patients(clinician_profile: dict = Depends(get_current_clinician_profile)):
    """Retrieves a list of all patients assigned to the currently authenticated clinician."""
    try:
        patients_response = supabase.table('patient_profiles').select('id, name, phone_number, risk_level, disease_logs(*), patient_monitor_data(measured_at)').eq('clinician_id', clinician_profile['id']).execute()
        return patients_response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve assigned patients: {str(e)}")

@router.get("/me/alerts", summary="Get priority alerts for assigned patients")
async def get_clinician_alerts(clinician_profile: dict = Depends(get_current_clinician_profile)):
    """
    Generates alerts based on patient data exceeding thresholds in the last 7 days.
    """
    try:
        # 1. Get all assigned patients
        patients = supabase.table('patient_profiles').select('id, name').eq('clinician_id', clinician_profile['id']).execute().data
        patient_ids = [p['id'] for p in patients]
        
        if not patient_ids:
            return []

        # 2. Get thresholds for these patients
        thresholds = supabase.table('patient_thresholds').select('*').in_('patient_id', patient_ids).execute().data
        # Map: patient_id -> { data_type: {min, max} }
        threshold_map = {}
        for t in thresholds:
            pid = t['patient_id']
            if pid not in threshold_map: threshold_map[pid] = {}
            threshold_map[pid][t['data_type']] = {'min': t['min_value'], 'max': t['max_value']}

        # 3. Get recent monitor data (limit to recent entries for performance)
        monitor_data = supabase.table('patient_monitor_data').select('*').in_('patient_id', patient_ids).order('measured_at', desc=True).limit(500).execute().data

        alerts = []
        
        for record in monitor_data:
            pid = record['patient_id']
            dtype = record['data_type']
            val = record['value']
            
            # Find threshold
            p_thresh = threshold_map.get(pid, {}).get(dtype)
            if not p_thresh: continue
            
            patient_name = next((p['name'] for p in patients if p['id'] == pid), "Unknown")
            
            alert_type = None
            desc = ""
            
            if val > p_thresh['max']:
                if dtype == 'GLUCOSE': 
                    alert_type = 'highGlucose'
                    desc = f"High Glucose: {val} mg/dL"
                elif dtype == 'BLOOD_PRESSURE_SYSTOLIC':
                    alert_type = 'highBloodPressure'
                    desc = f"High Systolic BP: {val} mmHg"
                elif dtype == 'HBA1C':
                    alert_type = 'highHbA1c'
                    desc = f"High HbA1c: {val}%"
            elif val < p_thresh['min']:
                if dtype == 'GLUCOSE':
                    alert_type = 'lowGlucose'
                    desc = f"Low Glucose: {val} mg/dL"
            
            if alert_type:
                alerts.append({
                    "id": str(record['id']),
                    "patientId": str(pid),
                    "patientName": patient_name,
                    "type": alert_type,
                    "timestamp": record['measured_at'],
                    "description": desc,
                    "dataPointRef": str(record['id'])
                })
        
        return alerts

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate alerts: {str(e)}")

@router.get("/available-patients", summary="Get list of unassigned patients")
async def get_available_patients(clinician_profile: dict = Depends(get_current_clinician_profile)):
    """Retrieves a list of patients who are not currently assigned to any clinician."""
    try:
        # Fetch patients where clinician_id is NULL
        patients_response = supabase.table('patient_profiles').select('id, name, phone_number, risk_level, disease_logs(*), patient_monitor_data(measured_at)').is_('clinician_id', 'null').execute()
        return patients_response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve available patients: {str(e)}")

@router.post("/patients/{patient_id}/assign", summary="Assign a patient to myself")
async def assign_patient_to_me(patient_id: int, clinician_profile: dict = Depends(get_current_clinician_profile)):
    """Assigns an unassigned patient to the current clinician."""
    try:
        # Check if patient is unassigned first to prevent stealing
        check = supabase.table('patient_profiles').select('clinician_id').eq('id', patient_id).single().execute()
        if check.data.get('clinician_id') is not None:
             raise HTTPException(status_code=400, detail="Patient is already assigned to a clinician.")

        update_payload = {
            "clinician_id": clinician_profile['id']
        }
        updated_patient = supabase.table('patient_profiles').update(update_payload).eq('id', patient_id).execute()
        
        return updated_patient.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to assign patient: {str(e)}")

@router.post("/patients/{patient_id}/unassign", summary="Unassign a patient from myself")
async def unassign_patient(patient_id: int, clinician_profile: dict = Depends(get_current_clinician_profile)):
    """Unassigns a patient from the current clinician."""
    try:
        # Verify patient is assigned to this clinician
        patient_check = supabase.table('patient_profiles').select('id', count='exact').eq('id', patient_id).eq('clinician_id', clinician_profile['id']).execute()
        if patient_check.count == 0:
            raise HTTPException(status_code=404, detail="Patient not found or not assigned to this clinician.")

        update_payload = {
            "clinician_id": None
        }
        updated_patient = supabase.table('patient_profiles').update(update_payload).eq('id', patient_id).execute()
        
        return updated_patient.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to unassign patient: {str(e)}")

@router.put("/me/patients/{patient_id}/profile", summary="Update assigned patient details")
async def update_assigned_patient_profile(
    patient_id: int,
    update_data: PatientProfileUpdate,
    clinician_profile: dict = Depends(get_current_clinician_profile)
):
    """Updates the profile of a patient assigned to the clinician."""
    # Verify patient is assigned
    check = supabase.table('patient_profiles').select('id').eq('id', patient_id).eq('clinician_id', clinician_profile['id']).execute()
    if not check.data:
        raise HTTPException(status_code=404, detail="Patient not found or not assigned to this clinician.")

    update_dict = update_data.model_dump(exclude_unset=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No update data provided.")

    try:
        updated = supabase.table('patient_profiles').update(update_dict).eq('id', patient_id).execute()
        return updated.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update patient profile: {str(e)}")

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
        disease_logs = supabase.table('disease_logs').select('*').eq('patient_id', patient_id).execute().data
        
        # Fetch medications with related dictionary and frequency data
        medications = supabase.table('patient_medications').select('''
            *,
            medication_dictionary(*),
            dosage_frequencies(*)
        ''').eq('patient_id', patient_id).eq('status', 'CURRENT').execute().data
        
        # Fetch activity using correct DB columns aliased for the frontend
        # Rename 'start_time' to 'performed_at' and 'active_duration_minutes' to 'duration_minutes'
        activity_logs = supabase.table('patient_activity_logs') \
            .select('*, performed_at:start_time, duration_minutes:active_duration_minutes') \
            .eq('patient_id', patient_id) \
            .order('start_time', desc=True) \
            .execute().data

        return {
            "profile": patient_profile,
            "monitor_data": monitor_data,
            "daily_logs": daily_logs,
            "thresholds": thresholds,
            "notes": notes,
            "activity_logs": activity_logs,
            "disease_logs": disease_logs,
            "medications": medications
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
