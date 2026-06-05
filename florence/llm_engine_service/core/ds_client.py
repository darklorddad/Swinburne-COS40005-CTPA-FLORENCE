import httpx
from fastapi import Header, HTTPException, status
from config import settings

async def get_auth_token(authorization: str = Header(...)) -> str:
    """Extracts the Bearer token from the request headers."""
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication scheme.",
        )
    return authorization.replace("Bearer ", "").strip()

async def fetch_user_settings(token: str) -> dict:
    """Fetches the user's unit preferences (mmol/L vs mg/dL) from the Data Service."""
    async with httpx.AsyncClient() as client:
        try:
            res = await client.get(
                f"{settings.DATA_SERVICE_URL}/patients/me/settings",
                headers={"Authorization": f"Bearer {token}"},
                timeout=5.0
            )
            if res.status_code == 200:
                return res.json()
        except Exception as e:
            print(f"[DS Client] Failed to fetch settings: {e}")
    # Fallback to base units if DS is unreachable
    return {"glucose_unit": "mmol/L", "cholesterol_unit": "mmol/L"}

async def fetch_user_thresholds(token: str) -> list:
    """Fetches the user's custom clinical thresholds from the Data Service."""
    async with httpx.AsyncClient() as client:
        try:
            res = await client.get(
                f"{settings.DATA_SERVICE_URL}/patients/me/thresholds",
                headers={"Authorization": f"Bearer {token}"},
                timeout=5.0
            )
            if res.status_code == 200:
                return res.json()
        except Exception as e:
            print(f"[DS Client] Failed to fetch thresholds: {e}")
    return []
