"""
Authentication utilities for validating JWT tokens via the Data Service.
"""
from fastapi import Header, HTTPException, status
from typing import Dict, Any
import httpx
from config import settings


async def get_current_patient(authorization: str = Header(...)) -> Dict[str, Any]:
    """
    FastAPI dependency to validate the patient via the Data Service.

    This function:
    1. Extracts Bearer token from Authorization header
    2. Calls the Data Service /patients/me endpoint
    3. Returns patient information and the token for downstream use

    Args:
        authorization: Authorization header value (Bearer <token>)

    Returns:
        Dict containing:
        - patient_id: Database patient ID
        - name: Patient name
        - token: The raw JWT token (to forward to Data Service)

    Raises:
        HTTPException:
            - 401: If token is missing, invalid, or expired
            - 403: If user is not a patient
            - 500: If Data Service is unreachable
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

    # Verify token by calling Data Service
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{settings.data_service_url}/patients/me",
                headers={"Authorization": f"Bearer {token}"},
                timeout=10.0
            )

            if response.status_code == 401:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid or expired token",
                )
            elif response.status_code == 403:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Access restricted to patients only",
                )
            elif response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Data Service error: {response.text}",
                )

            patient_profile = response.json()
            
            return {
                "patient_id": patient_profile["id"],
                "name": patient_profile.get("name"),
                "token": token
            }

        except httpx.RequestError as e:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=f"Could not connect to Data Service: {str(e)}",
            )


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
