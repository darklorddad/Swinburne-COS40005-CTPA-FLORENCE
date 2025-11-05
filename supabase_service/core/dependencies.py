from fastapi import Header, HTTPException
from supabase_auth.errors import AuthApiError
from gotrue.types import User

from ..client import supabase

async def get_current_user(authorization: str = Header(...)) -> User:
    """
    Dependency to get the current user from the JWT in the Authorization header.
    Handles token extraction and validation.
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authentication scheme.")
    
    token = authorization.split(" ")[1]
    
    try:
        user_response = await supabase.auth.get_user(token)
        user = user_response.user
        if not user:
            raise HTTPException(status_code=401, detail="Invalid token.")
        return user
    except AuthApiError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e.message}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
