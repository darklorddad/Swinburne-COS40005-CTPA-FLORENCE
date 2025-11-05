import logging
from fastapi import APIRouter, HTTPException, Header, Depends
from pydantic import BaseModel, EmailStr
from typing import Literal, Optional
from datetime import date
from supabase_auth.errors import AuthApiError
from gotrue.types import User as GotrueUser
from gotrue.models import User

# Import the shared Supabase client
from ..client import supabase
from ..core.dependencies import get_current_user
from ..core.constants import DEFAULT_THRESHOLDS

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
    gender: Optional[str] = None
    # Clinician specific
    organisation_id: Optional[int] = None
    # Patient specific
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

@router.post("/register")
async def register_user(user_data: UserRegistration):
    if user_data.role == 'CLINICIAN':
        if user_data.organisation_id is None:
            raise HTTPException(status_code=400, detail="Organisation ID is required for clinicians.")
        # Check if organisation exists before creating user
        org_check = await supabase.table('organisations').select('id', count='exact').eq('id', user_data.organisation_id).execute()
        if org_check.count == 0:
            raise HTTPException(status_code=404, detail=f"Organisation with id {user_data.organisation_id} not found.")

    new_user = None
    try:
        user_session = await supabase.auth.admin.create_user({
            "email": user_data.email,
            "password": user_data.password,
            "email_confirm": False, # Send email confirmation link, do not auto-confirm.
            "app_metadata": {"role": user_data.role}
        })
        new_user = user_session.user
        if not new_user:
            raise HTTPException(status_code=500, detail="Failed to create user in authentication system.")

    except AuthApiError as e:
        # Return a generic error to prevent user enumeration.
        # The actual error can be monitored in server logs.
        logging.warning(f"Registration AuthApiError: {e.message}")
        raise HTTPException(status_code=400, detail="User registration failed. Please check your details and try again.")
    
    try:
        if user_data.role == 'PATIENT':
            # Use the atomic RPC function to create profile and thresholds together
            rpc_params = {
                "p_user_id": str(new_user.id),
                "p_name": user_data.name,
                "p_phone_number": user_data.phone_number,
                "p_gender": user_data.gender,
                "p_date_of_birth": user_data.date_of_birth.isoformat() if user_data.date_of_birth else None,
                "p_emergency_contact_name": user_data.emergency_contact_name,
                "p_emergency_contact_relationship": user_data.emergency_contact_relationship,
                "p_emergency_contact_phone": user_data.emergency_contact_phone,
                "p_risk_level": "LOW", # Default risk level for new public sign-ups
                "p_organisation_id": None,
                "p_clinician_id": None,
            }
            profile_res = await supabase.rpc('create_patient_with_profile_and_thresholds', rpc_params).execute()
            if not profile_res.data:
                raise Exception("Failed to create patient profile and thresholds via RPC.")

        elif user_data.role == 'CLINICIAN':
            rpc_params = {
                "p_user_id": str(new_user.id),
                "p_name": user_data.name,
                "p_phone_number": user_data.phone_number,
                "p_gender": user_data.gender,
                "p_organisation_id": user_data.organisation_id,
            }
            profile_res = await supabase.rpc('create_clinician_with_profile', rpc_params).execute()
            if not profile_res.data:
                raise Exception("Failed to create clinician profile via RPC.")
        
        return {"message": f"{user_data.role.capitalize()} registered successfully. Please check your email for verification."}

    except Exception as e:
        if new_user:
            await supabase.auth.admin.delete_user(new_user.id)
        raise HTTPException(status_code=500, detail=f"Failed to create user profile: {str(e)}")


async def get_current_admin_user(user: GotrueUser = Depends(get_current_user)):
    """Dependency to get the current user and verify they are an admin."""
    # Explicitly check for the ADMIN role in app_metadata
    if user.app_metadata.get('role') != 'ADMIN':
        raise HTTPException(status_code=403, detail="Access denied: User is not an admin.")
    return user


@router.post("/register_admin", dependencies=[Depends(get_current_admin_user)])
async def register_admin(user_data: AdminRegistration):
    """
    Registers a new admin user and creates their profile.
    This endpoint is protected and only accessible by other admins.
    """
    new_user = None
    try:
        user_session = await supabase.auth.admin.create_user({
            "email": user_data.email,
            "password": user_data.password,
            "email_confirm": True,
            "app_metadata": {"role": "ADMIN"},
        })
        new_user = user_session.user
        if not new_user:
            raise HTTPException(status_code=500, detail="Failed to create admin user in authentication system.")

        # Create a corresponding profile in the admin_profiles table
        profile_data = {"user_id": new_user.id}
        profile_res = await supabase.table('admin_profiles').insert(profile_data).execute()

        if not profile_res.data:
            # If profile creation fails, roll back the auth user creation
            await supabase.auth.admin.delete_user(new_user.id)
            raise HTTPException(status_code=500, detail="Failed to create admin profile after user creation.")

        return {"message": "Admin registered successfully."}
    except AuthApiError as e:
        raise HTTPException(status_code=400, detail=f"Admin registration failed: {e.message}")
    except Exception as e:
        # Ensure rollback if any other exception occurs after user creation
        if new_user:
            await supabase.auth.admin.delete_user(new_user.id)
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")


@router.post("/login")
async def login_user(credentials: UserLogin):
    """Logs in a user and returns a session object with an access token."""
    try:
        response = await supabase.auth.sign_in_with_password({
            "email": credentials.email,
            "password": credentials.password
        })
        return response
    except AuthApiError as e:
        # Check for a specific server-side configuration error.
        if "Database error querying schema" in e.message:
            raise HTTPException(
                status_code=500, 
                detail="Login failed due to a server-side database configuration issue. Please contact an administrator."
            )
        # Otherwise, it's a normal authentication failure. Return a generic error to prevent user enumeration.
        logging.warning(f"Login failed for email {credentials.email}: {e.message}")
        raise HTTPException(status_code=401, detail="Invalid login credentials.")


@router.get("/me", response_model=User)
async def get_user_profile(user: GotrueUser = Depends(get_current_user)):
    """Retrieves the profile of the currently authenticated user based on the JWT."""
    return user
