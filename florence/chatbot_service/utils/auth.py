"""
Authentication utilities for validating JWT tokens and extracting patient information.
"""
from fastapi import Header, HTTPException, status
from jose import jwt, JWTError
from supabase import create_client, Client
from typing import Dict, Any
from config import settings
import httpx


# Initialize Supabase client
def get_supabase_client() -> Client:
    """Get Supabase client instance."""
    return create_client(settings.supabase_url, settings.supabase_service_key)


async def verify_jwt_token(token: str) -> Dict[str, Any]:
    """
    Verify JWT token with Supabase and return decoded payload.

    Args:
        token: JWT access token

    Returns:
        Dict containing user information from token

    Raises:
        HTTPException: If token is invalid or expired
    """
    try:
        # Verify with Supabase Auth
        supabase = get_supabase_client()

        # Use Supabase to verify the token
        response = supabase.auth.get_user(token)

        if not response or not response.user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication token",
                headers={"WWW-Authenticate": "Bearer"},
            )

        return {
            "user_id": response.user.id,
            "email": response.user.email,
            "role": response.user.app_metadata.get("role"),
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Could not validate credentials: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_patient_profile(user_id: str) -> Dict[str, Any]:
    """
    Fetch patient profile from database using user_id.

    Args:
        user_id: Supabase auth user ID

    Returns:
        Dict containing patient profile information

    Raises:
        HTTPException: If patient profile not found or user is not a patient
    """
    try:
        supabase = get_supabase_client()

        # Query patient_profiles table
        response = supabase.table("patient_profiles").select("*").eq("user_id", user_id).execute()

        if not response.data or len(response.data) == 0:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User is not a patient or profile not found",
            )

        return response.data[0]

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching patient profile: {str(e)}",
        )


async def get_current_patient(authorization: str = Header(...)) -> Dict[str, Any]:
    """
    FastAPI dependency to extract and validate patient from Authorization header.

    This function:
    1. Extracts Bearer token from Authorization header
    2. Validates JWT token with Supabase
    3. Fetches patient profile from database
    4. Returns patient information for use in endpoints

    Args:
        authorization: Authorization header value (Bearer <token>)

    Returns:
        Dict containing patient information:
        - patient_id: Database patient ID
        - user_id: Supabase auth user ID
        - email: Patient email
        - name: Patient name
        - role: User role

    Raises:
        HTTPException:
            - 401: If token is missing, invalid, or expired
            - 403: If user is not a patient
            - 500: If database query fails

    Usage:
        @app.get("/protected-endpoint")
        async def protected_route(patient: dict = Depends(get_current_patient)):
            patient_id = patient["patient_id"]
            # ... use patient_id for queries
    """
    # Extract Bearer token
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication scheme. Expected 'Bearer <token>'",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = authorization.replace("Bearer ", "").strip()

    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Verify token and get user info
    user_info = await verify_jwt_token(token)

    # Verify user is a patient
    if user_info.get("role") != "patient":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access restricted to patients only",
        )

    # Fetch patient profile
    patient_profile = await get_patient_profile(user_info["user_id"])

    return {
        "patient_id": patient_profile["id"],
        "user_id": user_info["user_id"],
        "email": user_info["email"],
        "name": patient_profile.get("name"),
        "role": user_info["role"],
    }


async def validate_patient_access(patient_id: int, resource_patient_id: int) -> None:
    """
    Validate that the authenticated patient has access to a resource.

    Args:
        patient_id: ID of authenticated patient
        resource_patient_id: ID of patient who owns the resource

    Raises:
        HTTPException: If patient IDs don't match (403 Forbidden)
    """
    if patient_id != resource_patient_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied: You can only access your own data",
        )
