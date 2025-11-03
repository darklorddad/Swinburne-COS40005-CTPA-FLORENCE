import os
import httpx
from pathlib import Path
from supabase import create_client, Client, ClientOptions
from dotenv import load_dotenv
from typing import Optional, Any

class _SupabaseClientProxy:
    _client: Optional[Client] = None

    def _get_client(self) -> Client:
        """
        Initialises and returns the Supabase client instance, ensuring it's a singleton.
        This lazy initialisation solves issues where environment variables might not be
        loaded at import time, especially during test runs.
        """
        if self._client is None:
            # Load environment variables from .env file in the project root.
            project_root = Path(__file__).resolve().parent.parent
            # By default, load_dotenv does not override existing environment variables.
            # This allows Vercel's environment variables to take precedence.
            load_dotenv(dotenv_path=project_root / '.env')

            url: str = os.environ.get("SUPABASE_URL")
            key: str = os.environ.get("SUPABASE_SERVICE_KEY")

            # --- Temporary debugging log ---
            if key:
                print(f"DEBUG: Supabase client using key starting with: {key[:5]}... and ending with: ...{key[-5:]}")
            else:
                print("DEBUG: SUPABASE_SERVICE_KEY not found in environment.")
            # -----------------------------

            if not url or not key:
                raise RuntimeError(
                    "Supabase URL and Service Key could not be loaded. "
                    "Ensure the SUPABASE_URL and SUPABASE_SERVICE_KEY environment variables are set correctly in your deployment."
                )

            # Configure client with a timeout.
            options = ClientOptions(
                postgrest_client_timeout=10,
                storage_client_timeout=10,
            )

            self._client = create_client(url, key, options=options)
        
        return self._client

    def __getattr__(self, name: str) -> Any:
        """
        Delegates attribute access to the actual Supabase client,
        initialising it if necessary.
        """
        client = self._get_client()
        return getattr(client, name)

# The global supabase object is an instance of the proxy.
# The actual client will be created only on first use.
supabase: Client = _SupabaseClientProxy()
