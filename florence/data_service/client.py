import os
from pathlib import Path
from supabase import create_async_client, AsyncClient, ClientOptions
from dotenv import load_dotenv
from typing import Optional, Any
import asyncio

# --- Client Proxies for Lazy Initialisation ---

class _SupabaseAdminClientProxy:
    """A proxy to lazily and asynchronously initialise the admin (service role) Supabase client."""
    _client: Optional[AsyncClient] = None
    _lock = asyncio.Lock()

    async def _get_client(self) -> AsyncClient:
        """Asynchronously gets/creates the client instance."""
        if self._client is None:
            async with self._lock:
                # Double-check lock pattern
                if self._client is None:
                    project_root = Path(__file__).resolve().parent.parent.parent
                    load_dotenv(dotenv_path=project_root / '.env')

                    url: str = os.environ.get("SUPABASE_URL")
                    key: str = os.environ.get("SUPABASE_SERVICE_KEY")

                    if not url or not key:
                        raise RuntimeError(
                            "SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in your environment."
                        )
                    
                    self._client = create_async_client(url, key, options=ClientOptions(postgrest_client_timeout=10))
        return self._client

    def __await__(self):
        return self._get_client().__await__()

    def __getattr__(self, name: str) -> Any:
        if self._client is None:
            raise RuntimeError(
                "Supabase admin client not initialized. You must 'await' the client proxy before using it (e.g., `client = await supabase_admin_client`)."
            )
        return getattr(self._client, name)

class _SupabaseAnonClientProxy:
    """A proxy to lazily and asynchronously initialise the anonymous Supabase client."""
    _client: Optional[AsyncClient] = None
    _lock = asyncio.Lock()

    async def _get_client(self) -> AsyncClient:
        """Asynchronously gets/creates the client instance."""
        if self._client is None:
            async with self._lock:
                # Double-check lock pattern
                if self._client is None:
                    project_root = Path(__file__).resolve().parent.parent.parent
                    load_dotenv(dotenv_path=project_root / '.env')

                    url: str = os.environ.get("SUPABASE_URL")
                    key: str = os.environ.get("SUPABASE_ANON_KEY")

                    if not url or not key:
                        raise RuntimeError(
                            "SUPABASE_URL and SUPABASE_ANON_KEY must be set in your environment."
                        )

                    self._client = create_async_client(url, key, options=ClientOptions(postgrest_client_timeout=10))
        return self._client

    def __await__(self):
        return self._get_client().__await__()

    def __getattr__(self, name: str) -> Any:
        if self._client is None:
            raise RuntimeError(
                "Supabase anonymous client not initialized. You must 'await' the client proxy before using it (e.g., `client = await supabase_anon_client`)."
            )
        return getattr(self._client, name)

# --- Exported Client Instances ---

# The admin client uses the SERVICE_KEY and bypasses RLS.
# Use this for administrative tasks and user management.
supabase_admin_client: Any = _SupabaseAdminClientProxy()

# The anonymous client uses the ANON_KEY.
# Use this for public operations like login.
supabase_anon_client: Any = _SupabaseAnonClientProxy()
