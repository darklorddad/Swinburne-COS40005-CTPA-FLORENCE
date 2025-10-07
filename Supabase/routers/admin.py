from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from enum import Enum
from datetime import date, datetime

from ..client import supabase
from .authentication import get_current_admin_user

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

class ClinicianProfileAdminUpdate(BaseModel):
    """Fields an admin is allowed to update on a clinician's profile."""
    name: Optional[str] = None
    phone_number: Optional[str] = None
    gender: Optional[str] = None
    organisation_id: Optional[int] = None

class OrganisationAdminUpdate(BaseModel):
    """Fields an admin is allowed to update on an organisation."""
    name: Optional[str] = None

# --- New Pydantic Models for Admin Updates ---

class MealTime(str, Enum):
    BREAKFAST = 'BREAKFAST'
    LUNCH = 'LUNCH'
    DINNER = 'DINNER'

class DailyLogAdminUpdate(BaseModel):
    log_date: Optional[date] = None
    meal_time: Optional[MealTime] = None
    glucose_before_meal: Optional[float] = None
    glucose_after_meal: Optional[float] = None
    meal_desc: Optional[str] = None

class MonitorDataType(str, Enum):
    BLOOD_PRESSURE_SYSTOLIC = 'BLOOD_PRESSURE_SYSTOLIC'
    BLOOD_PRESSURE_DIASTOLIC = 'BLOOD_PRESSURE_DIASTOLIC'
    GLUCOSE = 'GLUCOSE'
    BMI = 'BMI'
    HBA1C = 'HBA1C'
    ECG = 'ECG'
    CHOLESTEROL = 'CHOLESTEROL'

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
        # Select specific fields and related data from foreign tables
        patients_response = supabase.table('patient_profiles').select(
            "name, phone_number, gender, date_of_birth, "
            "emergency_contact_name, emergency_contact_relationship, emergency_contact_phone, "
            "risk_level, last_risk_assessment, "
            "organisations(name), "
            "clinician_profiles(name)"
        ).execute()

        # Process the data to create the desired flat structure
        processed_patients = []
        for patient in patients_response.data:
            org_data = patient.get('organisations')
            clinician_data = patient.get('clinician_profiles')
            
            age = None
            dob_str = patient.get("date_of_birth")
            if dob_str:
                try:
                    dob = date.fromisoformat(dob_str)
                    today = date.today()
                    age = today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))
                except (ValueError, TypeError):
                    age = None

            processed_patient = {
                "Name": patient.get("name"),
                "Phone Number": patient.get("phone_number"),
                "Gender": patient.get("gender"),
                "Date of Birth": patient.get("date_of_birth"),
                "Age": age,
                "Organisation Name": org_data.get("name") if org_data else None,
                "Emergency Contact Name": patient.get("emergency_contact_name"),
                "Emergency Contact Relationship": patient.get("emergency_contact_relationship"),
                "Emergency Contact Phone Number": patient.get("emergency_contact_phone"),
                "Clinician Name": clinician_data.get("name") if clinician_data else None,
                "Risk Level": patient.get("risk_level"),
                "Last Risk Assessment": patient.get("last_risk_assessment")
            }
            processed_patients.append(processed_patient)
            
        return processed_patients
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve patients: {str(e)}")


@router.get("/clinicians", summary="Get a list of all clinicians and their assigned patients")
async def get_all_clinicians():
    """Retrieves a list of all clinicians, their details, and the names of patients assigned to them."""
    try:
        # Fetch clinicians with their organisation and assigned patients' names
        clinicians_response = supabase.table('clinician_profiles').select(
            "name, phone_number, gender, "
            "organisations(name), "
            "patient_profiles(name)"
        ).execute()

        # Process the data to create the desired flat structure
        processed_clinicians = []
        for clinician in clinicians_response.data:
            org_data = clinician.get('organisations')
            patients_data = clinician.get('patient_profiles', [])
            
            processed_clinician = {
                "Name": clinician.get("name"),
                "Phone Number": clinician.get("phone_number"),
                "Gender": clinician.get("gender"),
                "Organisation Name": org_data.get("name") if org_data else None,
                "Assigned Patients": [patient['name'] for patient in patients_data if patient.get('name')]
            }
            processed_clinicians.append(processed_clinician)
            
        return processed_clinicians
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve clinicians: {str(e)}")


@router.get("/organisations", summary="Get a list of all organisations")
async def get_all_organisations():
    """Retrieves a list of all organisations in the system."""
    try:
        organisations_response = supabase.table('organisations').select('*').execute()
        return organisations_response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve organisations: {str(e)}")


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

        # Step 2: If patient is assigned to a clinician, remove related data (e.g., notes).
        # This prevents foreign key violations if ON DELETE CASCADE is not set.
        if patient_profile.get("clinician_id"):
            supabase.table('clinician_notes').delete().eq('patient_id', patient_id).execute()

        # Step 3: Delete the patient's profile from the database.
        # Note: This assumes other dependencies (monitor data, logs) are handled by CASCADE.
        deleted_profile_response = supabase.table('patient_profiles').delete().eq('id', patient_id).execute()
        
        if not deleted_profile_response.data:
            # This is a safeguard; it shouldn't be reached if the initial fetch succeeded.
            raise HTTPException(status_code=500, detail=f"Failed to delete patient profile {patient_id} after it was found.")
        
        # Step 4: If there's an associated auth user, delete them.
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


