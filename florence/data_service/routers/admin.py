from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from enum import Enum
from datetime import date, datetime, timedelta, timezone

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
    Deletes a patient's profile. Note: This does not automatically delete the user from
    Supabase Auth. That must be done separately if required.
    """
    try:
        deleted_profile_response = supabase.table('patient_profiles').delete().eq('id', patient_id).execute()
        if not deleted_profile_response.data:
            raise HTTPException(status_code=404, detail=f"Patient with id {patient_id} not found.")
        
        return {"message": f"Patient profile with id {patient_id} deleted successfully."}
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

@router.delete("/maintenance/cleanup-images", summary="Garbage collect orphaned images")
async def cleanup_orphaned_images():
    """
    Scans for images in Storage that are not linked to any DB record and deletes them.
    Safety: Only deletes images older than 1 hour to avoid race conditions with active uploads.
    """
    try:
        # 1. Get all valid photo URLs from the database
        # We only care about the path part, assuming URL structure: .../Meal_Photos/USER_ID/FILENAME
        logs_response = supabase.table('daily_patient_logs')\
            .select('photo_url')\
            .neq('photo_url', 'null')\
            .execute()
        
        # Create a set of valid unique paths: "user_id/filename.ext"
        # We need to extract the user_id and filename from the full URL.
        # URL format usually: .../Meal_Photos/USER_ID/FILENAME.ext
        valid_paths = set()
        
        for record in logs_response.data:
            url = record.get('photo_url')
            if url and "Meal_Photos/" in url:
                try:
                    # Split by 'Meal_Photos/' and take the part after it
                    # e.g., "USER_123/179999.jpg"
                    relative_path = url.split("Meal_Photos/")[-1]
                    # Decode URL encoding just in case (though rare for numeric IDs)
                    from urllib.parse import unquote
                    valid_paths.add(unquote(relative_path))
                except:
                    continue

        # 2. List all User Folders in 'Meal_Photos' bucket
        top_level = supabase.storage.from_("Bucket").list("Meal_Photos")
        
        deleted_count = 0
        errors = []

        # Threshold: 1 hour ago (UTC)
        threshold_time = datetime.now(timezone.utc) - timedelta(hours=1)

        for folder in top_level:
            if folder['name'] == '.emptyFolderPlaceholder': continue
            
            user_id = folder['name']
            user_path_prefix = f"Meal_Photos/{user_id}"
            
            # List files inside user folder
            user_files = supabase.storage.from_("Bucket").list(user_path_prefix)
            
            for file in user_files:
                file_name = file['name']
                
                # Construct the unique identifier key: "USER_ID/FILENAME"
                # This must match what we extracted from the DB URL above
                unique_key = f"{user_id}/{file_name}"

                # Check creation time
                try:
                    created_at_str = file['created_at'].replace('Z', '+00:00')
                    created_at = datetime.fromisoformat(created_at_str)
                    
                    if created_at > threshold_time:
                        continue
                except:
                    continue

                # 3. Compare: If file exists in storage but this specific User/File combo is NOT in DB
                if unique_key not in valid_paths:
                    full_delete_path = f"{user_path_prefix}/{file_name}"
                    print(f"Deleting orphan: {full_delete_path}")
                    
                    try:
                        supabase.storage.from_("Bucket").remove([full_delete_path])
                        deleted_count += 1
                    except Exception as del_err:
                        errors.append(f"Failed to delete {full_delete_path}: {str(del_err)}")

        return {
            "message": "Cleanup complete",
            "deleted_count": deleted_count,
            "errors": errors
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Cleanup failed: {str(e)}")
