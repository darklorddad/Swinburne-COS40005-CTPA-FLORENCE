from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from enum import Enum
from datetime import date

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

class AssignClinician(BaseModel):
    clinician_id: Optional[int] = None # Use None to unassign

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
            
            processed_patient = {
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
                "Last Risk Assessment": patient.get("last_risk_assessment")
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
    Deletes a patient's profile from the database and also deletes the
    corresponding user from Supabase Auth.
    """
    try:
        # First, delete the profile and retrieve it to get the user_id
        deleted_profile_response = supabase.table('patient_profiles').delete().eq('id', patient_id).execute()
        
        if not deleted_profile_response.data:
            raise HTTPException(status_code=404, detail=f"Patient with id {patient_id} not found.")
        
        patient_profile = deleted_profile_response.data[0]
        user_id = patient_profile.get("user_id")

        if not user_id:
            # This case should ideally not happen if data integrity is maintained.
            return {"message": f"Patient profile with id {patient_id} deleted, but no associated auth user to delete."}

        # Now, delete the user from Supabase Auth
        try:
            supabase.auth.admin.delete_user(user_id)
        except Exception as auth_error:
            # If auth deletion fails, the profile is already gone.
            # We should inform the admin about this partial failure.
            raise HTTPException(
                status_code=500, 
                detail=f"Patient profile {patient_id} deleted, but failed to delete user {user_id} from auth: {str(auth_error)}"
            )

        return {"message": f"Patient profile with id {patient_id} and associated auth user deleted successfully."}
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete patient: {str(e)}")

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
