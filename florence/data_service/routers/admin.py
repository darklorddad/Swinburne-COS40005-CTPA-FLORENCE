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

        # 3. Determine the latest alert per patient
        patient_alerts = {}
        for row in glucose_res.data:
            pid = row['patient_id']
            if pid not in patient_alerts:
                val = row['value']
                # Dynamic check for both mmol/L (usually < 25) and mg/dL (usually > 25)
                is_mgdl = val > 25
                hypo_thresh = 70.0 if is_mgdl else 3.9
                hyper_thresh = 180.0 if is_mgdl else 10.0
                
                if val < hypo_thresh:
                    patient_alerts[pid] = "Hypoglycemic Event"
                elif val > hyper_thresh:
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