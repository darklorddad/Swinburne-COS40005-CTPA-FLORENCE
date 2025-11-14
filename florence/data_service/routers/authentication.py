from fastapi import APIRouter, HTTPException, Header, Depends
from pydantic import BaseModel, EmailStr
from typing import Literal, Optional
from datetime import date
from supabase_auth.errors import AuthApiError

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
    phone_number: Optional[str] = None
    # Clinician specific
    organisation_id: Optional[int] = None
    # Patient specific
    gender: Optional[str] = None
    date_of_birth: Optional[date] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_relationship: Optional[str] = None
    emergency_contact_phone: Optional[str] = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class AdminRegistration(BaseModel):
    email: EmailStr
    password: str


DEFAULT_THRESHOLDS = [
    {'data_type': 'GLUCOSE', 'min_value': 70.0, 'max_value': 180.0},
    {'data_type': 'HBA1C', 'min_value': 4.0, 'max_value': 7.0},
    {'data_type': 'BMI', 'min_value': 18.5, 'max_value': 24.9},
    {'data_type': 'CHOLESTEROL', 'min_value': 100.0, 'max_value': 199.0},
    {'data_type': 'ECG', 'min_value': 60.0, 'max_value': 100},
    {'data_type': 'BLOOD_PRESSURE_SYSTOLIC', 'min_value': 90.0, 'max_value': 120},
    {'data_type': 'BLOOD_PRESSURE_DIASTOLIC', 'min_value': 60.0, 'max_value': 80}

    # NOTE: BLOOD_PRESSURE is not added by default because its value (e.g., "120/80")
    # doesn't fit the `min_value`/`max_value` NUMERIC columns in the `patient_thresholds` table.
    # A clinician or admin should set this manually based on a specific metric (e.g., Systolic only).
    # NOTE: ECG is also not added as its result is typically qualitative (e.g., "Normal Sinus Rhythm")
    # and does not have a simple numeric min/max threshold.
]

@router.post("/register")
async def register_user(user_data: UserRegistration):
    if user_data.role == 'CLINICIAN' and user_data.organisation_id is None:
        raise HTTPException(status_code=400, detail="Organisation ID is required for clinicians.")

    new_user = None
    try:
        user_session = supabase.auth.sign_up({
            "email": user_data.email,
            "password": user_data.password,
            "options": {
                "email_redirect_to": "florence://login-callback",
            }
        })
        new_user = user_session.user
        if not new_user:
            raise HTTPException(status_code=500, detail="Failed to create user in authentication system.")

        # After creating the user, update their app_metadata with the role using an admin call.
        # This is necessary because sign_up doesn't allow setting app_metadata directly.
        supabase.auth.admin.update_user_by_id(
            new_user.id, {"app_metadata": {"role": user_data.role}}
        )

    except AuthApiError as e:
        raise HTTPException(status_code=400, detail=f"User registration failed: {e.message}")
    
    try:
        if user_data.role == 'PATIENT':
            profile_data = {
                "user_id": new_user.id, "name": user_data.name, "phone_number": user_data.phone_number,
                "gender": user_data.gender,
                "date_of_birth": user_data.date_of_birth.isoformat() if user_data.date_of_birth else None,
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


async def get_current_admin_user(authorization: str = Header(...)):
    """Dependency to get the current user and verify they are an admin."""
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authentication scheme.")
    
    token = authorization.split(" ")[1]
    
    try:
        user_response = supabase.auth.get_user(token)
        user = user_response.user
        if not user:
            raise HTTPException(status_code=401, detail="Invalid token.")
        
        if user.app_metadata.get('role', '').upper() != 'ADMIN':
            raise HTTPException(status_code=403, detail="Access denied: User is not an admin.")
            
        return user
    except AuthApiError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e.message}")
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/register_admin", dependencies=[Depends(get_current_admin_user)])
async def register_admin(user_data: AdminRegistration):
    """Registers a new admin user. This endpoint is protected and only accessible by other admins."""
    try:
        supabase.auth.admin.create_user({
            "email": user_data.email,
            "password": user_data.password,
            "email_confirm": True,
            "app_metadata": {"role": "ADMIN"},
        })
        return {"message": "Admin registered successfully."}
    except AuthApiError as e:
        raise HTTPException(status_code=400, detail=f"Admin registration failed: {e.message}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")


@router.post("/login")
async def login_user(credentials: UserLogin):
    """Logs in a user and returns a session object with an access token."""
    try:
        response = supabase.auth.sign_in_with_password({
            "email": credentials.email,
            "password": credentials.password
        })
        return response.session
    except AuthApiError as e:
        # Supabase often returns a generic "Invalid login credentials" message.
        raise HTTPException(status_code=401, detail=f"Login failed: {e.message}")


@router.get("/me")
async def get_current_user(authorization: str = Header(...)):
    """Retrieves the profile of the currently authenticated user based on the JWT."""
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authentication scheme.")
    
    token = authorization.split(" ")[1]
    
    try:
        user_response = supabase.auth.get_user(token)
        user = user_response.user
        # Manually construct the response to ensure correct key names ('app_metadata')
        # for the Flutter client, which expects this instead of 'raw_app_meta_data'.
        return {
            "id": user.id,
            "aud": user.aud,
            "role": user.role,
            "email": user.email,
            "created_at": user.created_at.isoformat(),
            "app_metadata": user.app_metadata,
            "user_metadata": user.user_metadata,
        }
    except AuthApiError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e.message}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
