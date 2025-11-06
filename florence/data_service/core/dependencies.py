import logging
import os
from fastapi import Header, HTTPException, Depends
from supabase_auth.errors import AuthApiError
from gotrue.types import User
from supabase import create_async_client, AsyncClient, ClientOptions

from ..client import get_supabase_admin_client

async def get_auth_token(authorization: str = Header(...)) -> str:
    """Dependency to extract the JWT from the Authorization header."""
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authentication scheme.")
    return authorization.split(" ")[1]

async def get_current_user(token: str = Depends(get_auth_token)) -> User:
    """
    Dependency to get the current user from the JWT.
    Uses the admin client for validation as a trusted server-side operation.
    """
    try:
        admin_client = await get_supabase_admin_client()
        user_response = await admin_client.auth.get_user(token)
        user = user_response.user
        if not user:
            raise HTTPException(status_code=401, detail="Invalid token.")
        return user
    except AuthApiError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e.message}")
    except Exception as e:
        logging.error(f"Unexpected error during user validation: {e}")
        raise HTTPException(status_code=500, detail="An internal server error occurred.")

async def get_user_supabase_client(token: str = Depends(get_auth_token)) -> AsyncClient:
    """
    Dependency that creates a new Supabase client for each request,
    authenticated as the user making the request. This allows RLS to be enforced.
    """
    url: str = os.environ.get("SUPABASE_URL")
    key: str = os.environ.get("SUPABASE_ANON_KEY")

    if not url or not key:
        # This should have been caught on startup by the anon client, but as a safeguard:
        raise RuntimeError("SUPABASE_URL and SUPABASE_ANON_KEY must be set.")

    # Create a new client instance for this request, with the user's token.
    # This ensures that all subsequent operations with this client instance
    # are performed with the user's permissions, enforcing RLS.
    return create_async_client(
        url,
        key,
        options=ClientOptions(
            postgrest_client_timeout=10,
            storage_client_timeout=10,
            headers={"Authorization": f"Bearer {token}"},
        ),
    )
