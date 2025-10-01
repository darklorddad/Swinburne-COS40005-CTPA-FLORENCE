from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr
from typing import Literal, Optional
from gotrue.errors import AuthApiError

# Import the shared Supabase client
from ..client import supabase

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)

class UserRegistration(BaseModel):
    email: EmailStr
    password: str
    role: Literal['PATIENT', 'CLINICIAN']
    name: str
    phone_number: str
    # Clinician specific
    organisation_id: Optional[int] = None
    # Patient specific
    emergency_contact_name: Optional[str] = None
    emergency_contact_relationship: Optional[str] = None
    emergency_contact_phone: Optional[str] = None

DEFAULT_THRESHOLDS = [
    {'data_type': 'GLUCOSE', 'min_value': 70.0, 'max_value': 180.0},
    {'data_type': 'HBA1C', 'min_value': 4.0, 'max_value': 7.0},
    {'data_type': 'BMI', 'min_value': 18.5, 'max_value': 24.9},
]

@router.post("/register")
async def register_user(user_data: UserRegistration):
    if user_data.role == 'CLINICAN' and user_data.organisation_id is None:
        raise HTTPException(status_code=400, detail="Organisation ID is required for clinicians.")

    new_user = None
    try:
        user_session = supabase.auth.sign_up({
            "email": user_data.email,
            "password": user_data.password,
        })
        new_user = user_session.user
        if not new_user:
            raise HTTPException(status_code=500, detail="Failed to create user in authentication system.")

    except AuthApiError as e:
        raise HTTPException(status_code=400, detail=f"User registration failed: {e.message}")
    
    try:
        if user_data.role == 'PATIENT':
            profile_data = {
                "user_id": new_user.id, "name": user_data.name, "phone_number": user_data.phone_number,
                "emergency_contact_name": user_data.emergency_contact_name,
                "emergency_contact_relationship": user_data.emergency_contact_relationship,
                "emergency_contact_phone": user_data.emergency_contact_phone,
            }
            patient_profile = supabase.table('patient_profiles').insert(profile_data).execute().data[0]
            
            thresholds_to_insert = [
                {**threshold, 'patient_id': patient_profile['id']} for threshold in DEFAULT_THRESHOLDS
            ]
            supabase.table('patient_thresholds').insert(thresholds_to_insert).execute()

        elif user_data.role == 'CLINICIAN':
            profile_data = {
                "user_id": new_user.id, "name": user_data.name, "phone_number": user_data.phone_number,
                "organisation_id": user_data.organisation_id,
            }
            supabase.table('clinician_profiles').insert(profile_data).execute()
        
        return {"message": f"{user_data.role.capitalize()} registered successfully. Please check your email for verification."}

    except Exception as e:
        if new_user:
            supabase.auth.admin.delete_user(new_user.id)
        raise HTTPException(status_code=500, detail=f"Failed to create user profile: {str(e)}")
