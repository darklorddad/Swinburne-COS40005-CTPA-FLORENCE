from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from enum import Enum
from datetime import date, datetime, timedelta

from client import supabase
from routers.authentication import get_current_admin_user

# --- Pydantic Models ---

class RiskLevel(str, Enum):
    LOW = 'LOW'
    MEDIUM = 'MEDIUM'
    HIGH = 'HIGH'

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

class AssignClinician(BaseModel):
    clinician_id: Optional[int] = None # Use None to unassign

class SimulatorRequest(BaseModel):
    email: str
    password: str
    name: str
    scenario: str
    days: int = 30

class GenerateDataRequest(BaseModel):
    scenario: str
    days: int = 30

DEFAULT_THRESHOLDS = [
    {"data_type": "GLUCOSE", "min_value": 3.9, "max_value": 10.0},
    {"data_type": "BLOOD_PRESSURE_SYSTOLIC", "min_value": 90.0, "max_value": 140.0},
    {"data_type": "BLOOD_PRESSURE_DIASTOLIC", "min_value": 60.0, "max_value": 90.0}
]

class OrganisationCreate(BaseModel):
    name: str
    phone_number: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None
    sector: Optional[str] = None
    facility_type: Optional[str] = None
    full_address: Optional[str] = None
    state: Optional[str] = None
    is_24_hours: bool = False
    operating_hours: Optional[str] = None

class OrganisationUpdate(BaseModel):
    name: Optional[str] = None
    phone_number: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None
    sector: Optional[str] = None
    facility_type: Optional[str] = None
    full_address: Optional[str] = None
    state: Optional[str] = None
    is_24_hours: Optional[bool] = None
    operating_hours: Optional[str] = None

# --- Router Definition ---

router = APIRouter(
    prefix="/admin",
    tags=["Admin (Global Management)"],
    dependencies=[Depends(get_current_admin_user)] # Protect all routes in this router
)

# --- Endpoints ---

@router.get("/patients", summary="Get a list of all patients")
async def get_all_patients():
    """Retrieves a list of all patient profiles in the system."""
    try:
        # Select specific fields and related data from foreign tables
        patients_response = supabase.table('patient_profiles').select(
            "id, name, phone_number, gender, date_of_birth, "
            "emergency_contact_name, emergency_contact_relationship, emergency_contact_phone, "
            "risk_level, last_risk_assessment, "
            "organisations(name), "
            "clinician_profiles(name)"
        ).execute()

        # 2. Fetch Recent Glucose (Last 24 Hours) for Hypo/Hyper alerts
        yesterday = (datetime.now() - timedelta(days=1)).isoformat()
        glucose_res = supabase.table('patient_monitor_data')\
            .select('patient_id, value')\
            .eq('data_type', 'GLUCOSE')\
            .gte('measured_at', yesterday)\
            .order('measured_at', desc=True)\
            .execute()

        # 3. Fetch specific patient thresholds to accurately check Hypo/Hyper (All DB values are strictly mmol/L)
        patient_ids = list(set([row['patient_id'] for row in glucose_res.data]))
        thresholds_res = supabase.table('patient_thresholds')\
            .select('patient_id, min_value, max_value')\
            .eq('data_type', 'GLUCOSE')\
            .in_('patient_id', patient_ids)\
            .execute()
            
        thresholds_map = {t['patient_id']: t for t in thresholds_res.data}

        # 4. Determine the latest alert per patient
        patient_alerts = {}
        for row in glucose_res.data:
            pid = row['patient_id']
            if pid not in patient_alerts:
                val = row['value']
                thresh = thresholds_map.get(pid, {'min_value': 3.9, 'max_value': 10.0})
                
                if val < thresh['min_value']:
                    patient_alerts[pid] = "Hypoglycemic Event"
                elif val > thresh['max_value']:
                    patient_alerts[pid] = "Hyperglycemic Event"
                else:
                    patient_alerts[pid] = "Normal"

        # Process the data to create the desired flat structure
        processed_patients = []
        for patient in patients_response.data:
            org_data = patient.get('organisations')
            clinician_data = patient.get('clinician_profiles')
            pid = patient.get("id")

            # Attach alert if critical
            latest_alert = patient_alerts.get(pid)
            if latest_alert == "Normal":
                latest_alert = None

            processed_patient = {
                "id": pid,
                "Name": patient.get("name"),
                "Phone Number": patient.get("phone_number"),
                "Gender": patient.get("gender"),
                "Date of Birth": patient.get("date_of_birth"),
                "Organisation Name": org_data.get("name") if org_data else None,
                "Emergency Contact Name": patient.get("emergency_contact_name"),
                "Emergency Contact Relationship": patient.get("emergency_contact_relationship"),
                "Emergency Contact Phone Number": patient.get("emergency_contact_phone"),
                "Clinician Name": clinician_data.get("name") if clinician_data else None,
                "Risk Level": patient.get("risk_level"),
                "Last Risk Assessment": patient.get("last_risk_assessment"),
                "Latest Alert": latest_alert
            }
            processed_patients.append(processed_patient)
            
        return processed_patients
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve patients: {str(e)}")

@router.put("/patients/{patient_id}", summary="Edit any patient (including risk level)")
async def update_patient_by_admin(patient_id: int, update_data: PatientProfileAdminUpdate):
    """Updates any patient's profile. Can be used to change risk level or other details."""
    update_dict = update_data.model_dump(exclude_unset=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No update data provided.")

    try:
        if 'risk_level' in update_dict:
            update_dict['last_risk_assessment'] = datetime.now().isoformat()
        updated_profile_response = supabase.table('patient_profiles').update(update_dict).eq('id', patient_id).execute()
        if not updated_profile_response.data:
            raise HTTPException(status_code=404, detail=f"Patient with id {patient_id} not found.")
        return updated_profile_response.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update patient profile: {str(e)}")

@router.delete("/patients/{patient_id}", summary="Remove any patient")
async def delete_patient_by_admin(patient_id: int):
    """
    Deletes a patient's profile and completely removes their account from Supabase Auth.
    """
    try:
        profile = supabase.table('patient_profiles').select('user_id').eq('id', patient_id).execute()
        if not profile.data:
            raise HTTPException(status_code=404, detail=f"Patient with id {patient_id} not found.")
        
        user_id = profile.data[0]['user_id']
        
        # Delete from DB (Triggers CASCADE if setup, but we do Auth delete next to wipe them fully)
        supabase.table('patient_profiles').delete().eq('id', patient_id).execute()
        try:
            supabase.auth.admin.delete_user(user_id)
        except Exception:
            pass
        
        return {"message": "Patient account completely wiped successfully."}
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete patient: {str(e)}")

@router.delete("/patients/{patient_id}/data", summary="Wipe patient health data (Keep Account)")
async def wipe_patient_data(patient_id: int):
    """Deletes all health logs, activity, and monitor data for a patient but keeps their profile and Auth user."""
    try:
        supabase.table('patient_monitor_data').delete().eq('patient_id', patient_id).execute()
        supabase.table('daily_patient_logs').delete().eq('patient_id', patient_id).execute()
        supabase.table('patient_activity_logs').delete().eq('patient_id', patient_id).execute()
        supabase.table('patient_recommendations').delete().eq('patient_id', patient_id).execute()
        # Note: We leave disease logs, medications, and clinician notes intact as they are part of the medical profile.
        return {"message": "Patient health data wiped successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/patients/{patient_id}/generate-data", summary="Generate synthetic data for existing patient")
async def generate_data_for_existing_patient(patient_id: int, req: GenerateDataRequest):
    """Calls LLM Engine to generate 30 days of data and inserts it into an existing patient account."""
    import httpx
    import os

    # 1. Call LLM Engine
    async with httpx.AsyncClient(timeout=120.0) as client:
        llm_url = os.getenv("LLM_ENGINE_SERVICE_URL", "https://dev-llmes-florence-dhp.vercel.app")
        try:
            res = await client.post(f"{llm_url}/simulator/generate", json={"scenario": req.scenario, "days": req.days})
            res.raise_for_status()
            sim_data = res.json()
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"LLM Engine failed: {str(e)}")
    
    try:
        # 2. Parse LLM Data & Bulk Insert
        monitor_data = []
        daily_logs = []
        activity_logs = []
        now = datetime.now()

        for day in sim_data['days']:
            log_date = (now - timedelta(days=day['day_offset'])).date()
            base_time = datetime.combine(log_date, datetime.min.time())

            # BP
            monitor_data.append({"patient_id": patient_id, "data_type": "BLOOD_PRESSURE_SYSTOLIC", "value": day['systolic_bp'], "measured_at": (base_time + timedelta(hours=7)).isoformat()})
            monitor_data.append({"patient_id": patient_id, "data_type": "BLOOD_PRESSURE_DIASTOLIC", "value": day['diastolic_bp'], "measured_at": (base_time + timedelta(hours=7)).isoformat()})

            # Meals
            for meal in day['meals']:
                hour = 8 if meal['meal_time'] == 'BREAKFAST' else 13 if meal['meal_time'] == 'LUNCH' else 19
                before_time = base_time + timedelta(hours=hour)
                after_time = before_time + timedelta(hours=2)

                daily_logs.append({
                    "patient_id": patient_id,
                    "log_date": log_date.isoformat(),
                    "meal_time": meal['meal_time'],
                    "meal_desc": meal['description'],
                    "calories": meal['calories'],
                    "glucose_before_meal": meal['glucose_before'],
                    "glucose_after_meal": meal['glucose_after'],
                    "glucose_before_meal_time": before_time.isoformat(),
                    "glucose_after_meal_time": after_time.isoformat()
                })
                monitor_data.append({"patient_id": patient_id, "data_type": "GLUCOSE", "value": meal['glucose_before'], "measured_at": before_time.isoformat()})
                monitor_data.append({"patient_id": patient_id, "data_type": "GLUCOSE", "value": meal['glucose_after'], "measured_at": after_time.isoformat()})

            # Activity
            if day.get('activity'):
                act = day['activity']
                start = base_time + timedelta(hours=17)
                end = start + timedelta(minutes=act['duration_minutes'])
                activity_logs.append({
                    "patient_id": patient_id,
                    "activity_description": act['description'],
                    "active_duration_minutes": act['duration_minutes'],
                    "calories_burned": act['calories_burned'],
                    "start_time": start.isoformat(),
                    "end_time": end.isoformat()
                })

        # Monthly Vitals
        v_time = now.isoformat()
        monitor_data.extend([
            {"patient_id": patient_id, "data_type": "HBA1C", "value": sim_data['hba1c'], "measured_at": v_time},
            {"patient_id": patient_id, "data_type": "BMI", "value": sim_data['bmi'], "measured_at": v_time},
            {"patient_id": patient_id, "data_type": "CHOLESTEROL_TOTAL", "value": sim_data['cholesterol_total'], "measured_at": v_time},
            {"patient_id": patient_id, "data_type": "CHOLESTEROL_LDL", "value": sim_data['cholesterol_ldl'], "measured_at": v_time},
            {"patient_id": patient_id, "data_type": "CHOLESTEROL_HDL", "value": sim_data['cholesterol_hdl'], "measured_at": v_time},
            {"patient_id": patient_id, "data_type": "CHOLESTEROL_TRIGLYCERIDES", "value": sim_data['cholesterol_triglycerides'], "measured_at": v_time}
        ])

        if monitor_data: supabase.table('patient_monitor_data').insert(monitor_data).execute()
        if daily_logs: supabase.table('daily_patient_logs').insert(daily_logs).execute()
        if activity_logs: supabase.table('patient_activity_logs').insert(activity_logs).execute()

        # Update Risk Level based on scenario
        is_high_risk = "erratic" in req.scenario.lower() or "rollercoaster" in req.scenario.lower()
        supabase.table('patient_profiles').update({
            "risk_level": "HIGH" if is_high_risk else "LOW",
            "last_risk_assessment": now.isoformat()
        }).eq('id', patient_id).execute()

        return {"message": "Data generated successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database insertion failed: {str(e)}")

@router.post("/simulator/generate", summary="Generate a synthetic patient via LLM")
async def generate_synthetic_patient(req: SimulatorRequest):
    """Creates an auth user, generates 30 days of data via LLM Engine, and bulk inserts it."""
    import httpx
    import os

    # 1. Call LLM Engine (This can take 30+ seconds)
    async with httpx.AsyncClient(timeout=120.0) as client:
        # Defaults to localhost for local dev. Cloud uses Vercel Environment Variables.
        llm_url = os.getenv("LLM_ENGINE_SERVICE_URL", "https://dev-llmes-florence-dhp.vercel.app")
        try:
            res = await client.post(f"{llm_url}/simulator/generate", json={"scenario": req.scenario, "days": req.days})
            res.raise_for_status()
            sim_data = res.json()
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"LLM Engine failed to generate data: {str(e)}")

    # 2. Create User in Auth
    try:
        auth_res = supabase.auth.admin.create_user({
            "email": req.email,
            "password": req.password,
            "email_confirm": True,
            "user_metadata": {"name": req.name},
            "app_metadata": {"role": "PATIENT"}
        })
        user_id = auth_res.user.id
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Auth creation failed (Does email exist?): {str(e)}")

    try:
        # 3. Create Patient Profile
        is_high_risk = "erratic" in req.scenario.lower() or "rollercoaster" in req.scenario.lower()
        profile_res = supabase.table('patient_profiles').insert({
            "user_id": user_id,
            "name": req.name,
            "risk_level": "HIGH" if is_high_risk else "LOW"
        }).execute()
        patient_id = profile_res.data[0]['id']

        # Settings & Thresholds
        supabase.table('user_settings').upsert({"user_id": user_id, "glucose_unit": "mmol/L", "cholesterol_unit": "mmol/L"}).execute()
        thresholds = [{**t, 'patient_id': patient_id} for t in DEFAULT_THRESHOLDS]
        supabase.table('patient_thresholds').insert(thresholds).execute()

        # 4. Parse LLM Data & Bulk Insert
        monitor_data = []
        daily_logs = []
        activity_logs = []
        now = datetime.now()

        for day in sim_data['days']:
            log_date = (now - timedelta(days=day['day_offset'])).date()
            base_time = datetime.combine(log_date, datetime.min.time())

            # BP (Measured at 7 AM)
            monitor_data.append({"patient_id": patient_id, "data_type": "BLOOD_PRESSURE_SYSTOLIC", "value": day['systolic_bp'], "measured_at": (base_time + timedelta(hours=7)).isoformat()})
            monitor_data.append({"patient_id": patient_id, "data_type": "BLOOD_PRESSURE_DIASTOLIC", "value": day['diastolic_bp'], "measured_at": (base_time + timedelta(hours=7)).isoformat()})

            # Meals
            for meal in day['meals']:
                hour = 8 if meal['meal_time'] == 'BREAKFAST' else 13 if meal['meal_time'] == 'LUNCH' else 19
                before_time = base_time + timedelta(hours=hour)
                after_time = before_time + timedelta(hours=2)

                daily_logs.append({
                    "patient_id": patient_id,
                    "log_date": log_date.isoformat(),
                    "meal_time": meal['meal_time'],
                    "meal_desc": meal['description'],
                    "calories": meal['calories'],
                    "glucose_before_meal": meal['glucose_before'],
                    "glucose_after_meal": meal['glucose_after'],
                    "glucose_before_meal_time": before_time.isoformat(),
                    "glucose_after_meal_time": after_time.isoformat()
                })
                monitor_data.append({"patient_id": patient_id, "data_type": "GLUCOSE", "value": meal['glucose_before'], "measured_at": before_time.isoformat()})
                monitor_data.append({"patient_id": patient_id, "data_type": "GLUCOSE", "value": meal['glucose_after'], "measured_at": after_time.isoformat()})

            # Activity (Measured at 5 PM)
            if day.get('activity'):
                act = day['activity']
                start = base_time + timedelta(hours=17)
                end = start + timedelta(minutes=act['duration_minutes'])
                activity_logs.append({
                    "patient_id": patient_id,
                    "activity_description": act['description'],
                    "active_duration_minutes": act['duration_minutes'],
                    "calories_burned": act['calories_burned'],
                    "start_time": start.isoformat(),
                    "end_time": end.isoformat()
                })

        # Monthly Vitals
        v_time = now.isoformat()
        monitor_data.extend([
            {"patient_id": patient_id, "data_type": "HBA1C", "value": sim_data['hba1c'], "measured_at": v_time},
            {"patient_id": patient_id, "data_type": "BMI", "value": sim_data['bmi'], "measured_at": v_time},
            {"patient_id": patient_id, "data_type": "CHOLESTEROL_TOTAL", "value": sim_data['cholesterol_total'], "measured_at": v_time},
            {"patient_id": patient_id, "data_type": "CHOLESTEROL_LDL", "value": sim_data['cholesterol_ldl'], "measured_at": v_time},
            {"patient_id": patient_id, "data_type": "CHOLESTEROL_HDL", "value": sim_data['cholesterol_hdl'], "measured_at": v_time},
            {"patient_id": patient_id, "data_type": "CHOLESTEROL_TRIGLYCERIDES", "value": sim_data['cholesterol_triglycerides'], "measured_at": v_time}
        ])

        if monitor_data: supabase.table('patient_monitor_data').insert(monitor_data).execute()
        if daily_logs: supabase.table('daily_patient_logs').insert(daily_logs).execute()
        if activity_logs: supabase.table('patient_activity_logs').insert(activity_logs).execute()

        return {"message": "Synthetic patient generated successfully", "patient_id": patient_id}
        
    except Exception as e:
        # Cleanup if generation failed halfway
        try:
            supabase.auth.admin.delete_user(user_id)
        except Exception:
            pass
        raise HTTPException(status_code=500, detail=f"Database insertion failed: {str(e)}")

@router.put("/patients/{patient_id}/assign-clinician", summary="Assign/unassign a clinician to a patient")
async def assign_clinician_to_patient(patient_id: int, assignment: AssignClinician):
    """Assigns a clinician to a patient, or unassigns them if clinician_id is null."""
    update_dict = {"clinician_id": assignment.clinician_id}
    try:
        response = supabase.table('patient_profiles').update(update_dict).eq('id', patient_id).execute()
        if not response.data:
            raise HTTPException(status_code=404, detail=f"Patient with id {patient_id} not found.")
        return response.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to assign clinician: {str(e)}")

@router.get("/recent-activity", summary="Get recent system activities")
async def get_recent_activity():
    """
    Dynamically generates recent activity events based on recent risk assessments.
    """
    try:
        # Fetch the 5 most recently assessed patients
        response = supabase.table('patient_profiles').select(
            'id, name, risk_level, last_risk_assessment'
        ).not_.is_('last_risk_assessment', 'null').order('last_risk_assessment', desc=True).limit(5).execute()

        activities = []
        for p in response.data:
            is_high = p.get('risk_level', '').upper() == 'HIGH'
            activities.append({
                "id": str(p['id']),
                "title": "Risk Level Elevated" if is_high else "Risk Assessment Updated",
                "subtitle": f"{p['name']} updated to {p['risk_level']} risk",
                "timestamp": p['last_risk_assessment'],
                "icon_type": "warning" if is_high else "update"
            })
        
        return activities
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch activity: {str(e)}")

@router.get("/organisations", summary="Get a list of all organisations")
async def get_all_organisations():
    try:
        # Fetch organisations
        orgs_res = supabase.table('organisations').select('*').execute()
        
        # For MVP, we can fetch all patients and clinicians to calculate counts
        patients_res = supabase.table('patient_profiles').select('organisation_id').execute()
        clinicians_res = supabase.table('clinician_profiles').select('organisation_id').execute()

        # Count mappings
        patient_counts = {}
        for p in patients_res.data:
            oid = p.get('organisation_id')
            if oid:
                patient_counts[oid] = patient_counts.get(oid, 0) + 1
                
        clinician_counts = {}
        for c in clinicians_res.data:
            oid = c.get('organisation_id')
            if oid:
                clinician_counts[oid] = clinician_counts.get(oid, 0) + 1

        processed_orgs = []
        for org in orgs_res.data:
            org_id = org['id']
            org['patient_count'] = patient_counts.get(org_id, 0)
            org['clinician_count'] = clinician_counts.get(org_id, 0)
            processed_orgs.append(org)

        return processed_orgs
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve organisations: {str(e)}")

@router.post("/organisations", summary="Create an organisation")
async def create_organisation(org_data: OrganisationCreate):
    try:
        insert_dict = org_data.model_dump(exclude_unset=True)
        response = supabase.table('organisations').insert(insert_dict).execute()
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create organisation: {str(e)}")

@router.patch("/organisations/{org_id}", summary="Update an organisation")
async def update_organisation(org_id: int, org_data: OrganisationUpdate):
    try:
        update_dict = org_data.model_dump(exclude_unset=True)
        if not update_dict:
            raise HTTPException(status_code=400, detail="No data to update")
            
        response = supabase.table('organisations').update(update_dict).eq('id', org_id).execute()
        if not response.data:
            raise HTTPException(status_code=404, detail="Organisation not found")
        return response.data[0]
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update organisation: {str(e)}")

@router.delete("/organisations/{org_id}", summary="Delete an organisation")
async def delete_organisation(org_id: int):
    try:
        response = supabase.table('organisations').delete().eq('id', org_id).execute()
        if not response.data:
            raise HTTPException(status_code=404, detail="Organisation not found")
        return {"message": "Deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete organisation: {str(e)}")
