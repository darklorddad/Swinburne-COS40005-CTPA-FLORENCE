from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, model_validator, EmailStr
from typing import Optional
from enum import Enum
from datetime import date, datetime
from supabase_auth.errors import AuthApiError
import traceback

from ..client import supabase
from .authentication import get_current_admin_user
from ..core.constants import DEFAULT_THRESHOLDS
from ..models import MonitorDataType

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
        # Select all columns from patient_profiles and related data from foreign tables
        patients_response = supabase.table('patient_profiles').select(
            "*, "
            "organisations(name), "
            "clinician_profiles(name)"
        ).execute()

        # Add calculated age to each patient profile
        patients = patients_response.data
        for patient in patients:
            age = None
            dob_str = patient.get("date_of_birth")
            if dob_str:
                try:
                    dob = date.fromisoformat(dob_str)
                    today = date.today()
                    age = today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))
                except (ValueError, TypeError):
                    age = None
            patient['age'] = age
            
        return patients
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve patients: {str(e)}")


@router.post("/patients", summary="Add a new patient")
async def add_patient_by_admin(patient_data: PatientAdminCreate):
    """Creates a new patient, including their authentication user and profile."""
    new_user = None
    try:
        # Step 1: Create the user in Supabase Auth
        user_session = supabase.auth.admin.create_user({
            "email": patient_data.email,
            "password": patient_data.password,
            "email_confirm": True,  # Auto-confirm user
            "app_metadata": {"role": "PATIENT"}
        })
        new_user = user_session.user
        if not new_user:
            raise HTTPException(status_code=500, detail="Failed to create user in authentication system.")

        # Step 2: Create the patient profile
        profile_data = {
            "user_id": new_user.id,
            "name": patient_data.name,
            "phone_number": patient_data.phone_number,
            "gender": patient_data.gender,
            "date_of_birth": patient_data.date_of_birth.isoformat() if patient_data.date_of_birth else None,
            "emergency_contact_name": patient_data.emergency_contact_name,
            "emergency_contact_relationship": patient_data.emergency_contact_relationship,
            "emergency_contact_phone": patient_data.emergency_contact_phone,
            "risk_level": patient_data.risk_level.value if patient_data.risk_level else 'LOW',
            "organisation_id": patient_data.organisation_id,
            "clinician_id": patient_data.clinician_id,
        }
        patient_profile_res = supabase.table('patient_profiles').insert(profile_data).execute()
        if not patient_profile_res.data:
            raise Exception("Failed to create patient profile in database.")
        patient_profile = patient_profile_res.data[0]

        # Step 3: Create default thresholds for the new patient
        thresholds_to_insert = [
            {**threshold, 'patient_id': patient_profile['id']} for threshold in DEFAULT_THRESHOLDS
        ]
        supabase.table('patient_thresholds').insert(thresholds_to_insert).execute()

        return {"message": "Patient created successfully.", "profile": patient_profile}

    except AuthApiError as e:
        print(traceback.format_exc())
        print(f"AuthApiError during patient creation: {e.message}")
        raise HTTPException(status_code=400, detail=f"User creation failed: {e.message}")
    except Exception as e:
        # Print the full traceback to the logs for debugging on Vercel
        print(traceback.format_exc())
        # Rollback: delete the auth user if profile creation failed
        if new_user:
            supabase.auth.admin.delete_user(new_user.id)
        raise HTTPException(status_code=500, detail=f"Failed to create patient: {str(e)}")


@router.get("/clinicians", summary="Get a list of all clinicians and their assigned patients")
async def get_all_clinicians():
    """Retrieves a list of all clinicians, their details, and the names of patients assigned to them."""
    try:
        # Fetch clinicians with their organisation and assigned patients' names
        clinicians_response = supabase.table('clinician_profiles').select(
            "*, " # Select all columns from clinician_profiles
            "organisations(name), "
            "patient_profiles(name)"
        ).execute()

        # Process the data to simplify the nested patient list
        clinicians = clinicians_response.data
        for clinician in clinicians:
            # Replace the list of patient profile objects with just a list of names for simplicity
            patients_data = clinician.get('patient_profiles', [])
            clinician['assigned_patients'] = [patient['name'] for patient in patients_data if patient.get('name')]
            del clinician['patient_profiles'] # Remove the original nested list
            
        return clinicians
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve clinicians: {str(e)}")


@router.post("/clinicians", summary="Add a new clinician")
async def add_clinician_by_admin(clinician_data: ClinicianAdminCreate):
    """Creates a new clinician, including their authentication user and profile."""
    new_user = None
    try:
        # Step 1: Create the user in Supabase Auth
        user_session = supabase.auth.admin.create_user({
            "email": clinician_data.email,
            "password": clinician_data.password,
            "email_confirm": True,  # Auto-confirm user
            "app_metadata": {"role": "CLINICIAN"}
        })
        new_user = user_session.user
        if not new_user:
            raise HTTPException(status_code=500, detail="Failed to create user in authentication system.")

        # Step 2: Create the clinician profile
        profile_data = {
            "user_id": new_user.id,
            "name": clinician_data.name,
            "phone_number": clinician_data.phone_number,
            "gender": clinician_data.gender,
            "organisation_id": clinician_data.organisation_id,
        }
        clinician_profile_res = supabase.table('clinician_profiles').insert(profile_data).execute()
        if not clinician_profile_res.data:
            raise Exception("Failed to create clinician profile in database.")
        
        clinician_profile = clinician_profile_res.data[0]

        return {"message": "Clinician created successfully.", "profile": clinician_profile}

    except AuthApiError as e:
        print(traceback.format_exc())
        print(f"AuthApiError during clinician creation: {e.message}")
        raise HTTPException(status_code=400, detail=f"User creation failed: {e.message}")
    except Exception as e:
        # Rollback: delete the auth user if profile creation failed
        if new_user:
            supabase.auth.admin.delete_user(new_user.id)
        raise HTTPException(status_code=500, detail=f"Failed to create clinician: {str(e)}")


@router.get("/organisations", summary="Get a list of all organisations")
async def get_all_organisations():
    """Retrieves a list of all organisations in the system."""
    try:
        organisations_response = supabase.table('organisations').select('*').execute()
        return organisations_response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve organisations: {str(e)}")


@router.post("/organisations", summary="Add a new organisation")
async def add_organisation_by_admin(org_data: OrganisationAdminCreate):
    """Creates a new organisation."""
    try:
        response = supabase.table('organisations').insert({"name": org_data.name}).execute()
        if not response.data:
            raise HTTPException(status_code=500, detail="Failed to create organisation.")
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create organisation: {str(e)}")


@router.get("/daily-logs", summary="Get a list of all daily patient logs")
async def get_all_daily_logs():
    """Retrieves a list of all daily patient logs with patient names."""
    try:
        logs_response = supabase.table('daily_patient_logs').select(
            "*, " # Select all columns from daily_patient_logs
            "patient_profiles(name)"
        ).execute()
        
        return logs_response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve daily logs: {str(e)}")


@router.post("/daily-logs", summary="Add a daily patient log")
async def add_daily_log_by_admin(log_data: DailyLogAdminCreate):
    """Adds a new daily log entry for a specified patient."""
    try:
        insert_dict = log_data.model_dump(mode='json')
        
        # Check if patient exists
        patient_check = supabase.table('patient_profiles').select('id', count='exact').eq('id', log_data.patient_id).execute()
        if patient_check.count == 0:
            raise HTTPException(status_code=404, detail=f"Patient with id {log_data.patient_id} not found.")

        new_log_response = supabase.table('daily_patient_logs').insert(insert_dict).execute()
        if not new_log_response.data:
            raise HTTPException(status_code=500, detail="Failed to create daily log.")
        return new_log_response.data[0]
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException as e:
        raise e
    except Exception as e:
        if "duplicate key value violates unique constraint" in str(e):
            raise HTTPException(status_code=409, detail="A log for this patient, date and meal time already exists.")
        raise HTTPException(status_code=500, detail=f"Failed to add daily log: {str(e)}")


@router.delete("/daily-logs/{log_id}", summary="Remove a daily patient log")
async def delete_daily_log_by_admin(log_id: int):
    """Deletes a daily patient log entry by its ID."""
    try:
        response = supabase.table('daily_patient_logs').delete().eq('id', log_id).execute()
        if not response.data:
            raise HTTPException(status_code=404, detail=f"Daily log with id {log_id} not found.")
        return {"message": f"Daily log with id {log_id} deleted successfully."}
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete daily log: {str(e)}")


@router.get("/monitor-data", summary="Get a list of all patient monitor data")
async def get_all_monitor_data():
    """Retrieves a list of all patient monitor data points with patient names."""
    try:
        data_response = supabase.table('patient_monitor_data').select(
            "*, " # Select all columns from patient_monitor_data
            "patient_profiles(name)"
        ).execute()

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
        
        return data_response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve monitor data: {str(e)}")


@router.post("/monitor-data", summary="Add a patient monitor data point")
async def add_monitor_data_by_admin(data: MonitorDataAdminCreate):
    """Adds a new health monitor data point for a specified patient."""
    insert_dict = data.model_dump(mode='json')
    try:
        # Check if patient exists
        patient_check = supabase.table('patient_profiles').select('id', count='exact').eq('id', data.patient_id).execute()
        if patient_check.count == 0:
            raise HTTPException(status_code=404, detail=f"Patient with id {data.patient_id} not found.")

        new_data_response = supabase.table('patient_monitor_data').insert(insert_dict).execute()
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
        response = supabase.table('patient_monitor_data').delete().eq('id', data_id).execute()
        if not response.data:
            raise HTTPException(status_code=404, detail=f"Monitor data with id {data_id} not found.")
        return {"message": f"Monitor data with id {data_id} deleted successfully."}
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete monitor data: {str(e)}")


@router.get("/thresholds", summary="Get a list of all patient thresholds")
async def get_all_thresholds():
    """Retrieves a list of all patient thresholds with patient names."""
    try:
        thresholds_response = supabase.table('patient_thresholds').select(
            "*, " # Select all columns from patient_thresholds
            "patient_profiles(name)"
        ).execute()
        
        return thresholds_response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve thresholds: {str(e)}")


@router.put("/patients/{patient_id}", summary="Edit any patient (including risk level)")
async def update_patient_by_admin(patient_id: int, update_data: PatientProfileAdminUpdate):
    """Updates any patient's profile. Can be used to change risk level or other details."""
    update_dict = update_data.model_dump(exclude_unset=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No update data provided.")

    try:
        updated_profile_response = supabase.table('patient_profiles').update(update_dict).eq('id', patient_id).execute()
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
    update_dict = update_data.model_dump(exclude_unset=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No update data provided.")

    try:
        updated_profile_response = supabase.table('clinician_profiles').update(update_dict).eq('id', clinician_id).execute()
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
    update_dict = update_data.model_dump(exclude_unset=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No update data provided.")

    try:
        response = supabase.table('organisations').update(update_dict).eq('id', organisation_id).execute()
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
    Deletes an organisation. This is only possible if no clinicians are currently
    assigned to it. Any patients assigned to this organisation will be unassigned.
    """
    try:
        # Step 1: Check if any clinicians are assigned to this organisation.
        clinician_check = supabase.table('clinician_profiles').select('id', count='exact').eq('organisation_id', organisation_id).execute()
        if clinician_check.count > 0:
            raise HTTPException(
                status_code=409, # Conflict
                detail=f"Cannot delete organisation {organisation_id} because it has {clinician_check.count} clinician(s) assigned. Please reassign or delete them first."
            )

        # Step 2: Unassign any patients from this organisation.
        supabase.table('patient_profiles').update({"organisation_id": None}).eq('organisation_id', organisation_id).execute()

        # Step 3: Delete the organisation.
        response = supabase.table('organisations').delete().eq('id', organisation_id).execute()

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
    update_dict = update_data.model_dump(exclude_unset=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No update data provided.")

    try:
        response = supabase.table('daily_patient_logs').update(update_dict).eq('id', log_id).execute()
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
    update_dict = update_data.model_dump(exclude_unset=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No update data provided.")

    try:
        response = supabase.table('patient_monitor_data').update(update_dict).eq('id', data_id).execute()
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
    update_dict = update_data.model_dump(exclude_unset=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No update data provided.")

    try:
        response = supabase.table('patient_thresholds').update(update_dict).eq('id', threshold_id).execute()
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
    update_dict = update_data.model_dump(exclude_unset=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No update data provided.")

    try:
        response = supabase.table('clinician_notes').update(update_dict).eq('id', note_id).execute()
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
        # Step 1: Retrieve the patient's profile to get user_id and check for clinician assignment.
        # This also verifies the patient exists before proceeding.
        patient_profile_res = supabase.table('patient_profiles').select("user_id, clinician_id").eq('id', patient_id).single().execute()
        
        patient_profile = patient_profile_res.data
        user_id = patient_profile.get("user_id")

        # Step 2: Delete the patient's profile from the database.
        # Note: Related data (monitor data, logs, notes) is deleted automatically by 'ON DELETE CASCADE' in the database schema.
        deleted_profile_response = supabase.table('patient_profiles').delete().eq('id', patient_id).execute()
        
        if not deleted_profile_response.data:
            # This is a safeguard; it shouldn't be reached if the initial fetch succeeded.
            raise HTTPException(status_code=500, detail=f"Failed to delete patient profile {patient_id} after it was found.")
        
        # Step 3: If there's an associated auth user, delete them.
        if not user_id:
            return {"message": f"Patient profile with id {patient_id} deleted, but no associated auth user to delete."}

        try:
            supabase.auth.admin.delete_user(user_id)
        except Exception as auth_error:
            # The profile is already deleted, so we report a partial success with an error.
            raise HTTPException(
                status_code=500, 
                detail=f"Patient profile {patient_id} deleted, but failed to delete user {user_id} from auth: {str(auth_error)}"
            )

        return {"message": f"Patient profile with id {patient_id} and associated auth user deleted successfully."}
    except HTTPException as e:
        raise e
    except Exception as e:
        # Catch error from .single() if patient not found.
        if "Expected 1 row, got 0" in str(e):
            raise HTTPException(status_code=404, detail=f"Patient with id {patient_id} not found.")
        raise HTTPException(status_code=500, detail=f"Failed to delete patient: {str(e)}")


@router.delete("/clinicians/{clinician_id}", summary="Remove any clinician")
async def delete_clinician_by_admin(clinician_id: int):
    """
    Deletes a clinician's profile, unassigns their patients, removes their notes,
    and deletes the corresponding user from Supabase Auth.
    """
    try:
        # Step 1: Retrieve the clinician's profile to get user_id and name.
        clinician_profile_res = supabase.table('clinician_profiles').select("user_id, name").eq('id', clinician_id).single().execute()
        
        clinician_profile = clinician_profile_res.data
        user_id = clinician_profile.get("user_id")
        clinician_name = clinician_profile.get("name")

        # Step 2: Unassign all patients from this clinician.
        supabase.table('patient_profiles').update({"clinician_id": None}).eq('clinician_id', clinician_id).execute()

        # Step 3: Preserve notes by detaching them from the clinician and snapshotting their name.
        supabase.table('clinician_notes').update({
            "clinician_id": None,
            "clinician_name_snapshot": clinician_name
        }).eq('clinician_id', clinician_id).execute()

        # Step 4: Delete the clinician's profile.
        deleted_profile_response = supabase.table('clinician_profiles').delete().eq('id', clinician_id).execute()
        
        if not deleted_profile_response.data:
            raise HTTPException(status_code=500, detail=f"Failed to delete clinician profile {clinician_id} after it was found.")
        
        # Step 5: If there's an associated auth user, delete them.
        if not user_id:
            return {"message": f"Clinician profile with id {clinician_id} deleted, but no associated auth user to delete."}

        try:
            supabase.auth.admin.delete_user(user_id)
        except Exception as auth_error:
            raise HTTPException(
                status_code=500, 
                detail=f"Clinician profile {clinician_id} deleted, but failed to delete user {user_id} from auth: {str(auth_error)}"
            )

        return {"message": f"Clinician profile with id {clinician_id} and associated auth user deleted successfully."}
    except HTTPException as e:
        raise e
    except Exception as e:
        if "Expected 1 row, got 0" in str(e):
            raise HTTPException(status_code=404, detail=f"Clinician with id {clinician_id} not found.")
        raise HTTPException(status_code=500, detail=f"Failed to delete clinician: {str(e)}")


