import os
from pathlib import Path
from supabase import create_async_client, AsyncClient, ClientOptions
from dotenv import load_dotenv
from typing import Optional, Any
import asyncio

# --- Lazy Initialisation for Supabase Clients ---

_admin_client: Optional[AsyncClient] = None
_admin_client_lock = asyncio.Lock()

_anon_client: Optional[AsyncClient] = None
_anon_client_lock = asyncio.Lock()

async def get_supabase_admin_client() -> AsyncClient:
    """
    Lazily initializes and returns a Supabase client with admin (service role) privileges.
    This client bypasses RLS and should be used for administrative tasks.
    """
    global _admin_client
    if _admin_client is None:
        async with _admin_client_lock:
            # Double-check lock pattern
            if _admin_client is None:
                project_root = Path(__file__).resolve().parent.parent.parent
                load_dotenv(dotenv_path=project_root / '.env')

                url: str = os.environ.get("SUPABASE_URL")
                key: str = os.environ.get("SUPABASE_SERVICE_KEY")

                if not url or not key:
                    raise RuntimeError(
                        "SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in your environment."
                    )
                
                _admin_client = create_async_client(url, key, options=ClientOptions(postgrest_client_timeout=10))
    return _admin_client

async def get_supabase_anon_client() -> AsyncClient:
    """
    Lazily initializes and returns a Supabase client with anonymous user privileges.
    This client is subject to RLS and is used for public operations like login/signup.
    """
    global _anon_client
    if _anon_client is None:
        async with _anon_client_lock:
            # Double-check lock pattern
            if _anon_client is None:
                project_root = Path(__file__).resolve().parent.parent.parent
                load_dotenv(dotenv_path=project_root / '.env')

                url: str = os.environ.get("SUPABASE_URL")
                key: str = os.environ.get("SUPABASE_ANON_KEY")

                if not url or not key:
                    raise RuntimeError(
                        "SUPABASE_URL and SUPABASE_ANON_KEY must be set in your environment."
                    )

                _anon_client = create_async_client(url, key, options=ClientOptions(postgrest_client_timeout=10))
    return _anon_client
