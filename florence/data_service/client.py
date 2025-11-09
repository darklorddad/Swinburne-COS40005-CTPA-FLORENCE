import os
from pathlib import Path
from supabase import create_client, Client, ClientOptions
from supabase.client_options import AuthClientOptions, PostgrestClientOptions
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
            load_dotenv(dotenv_path=project_root / '.env', override=True)

            url: str = os.environ.get("SUPABASE_URL")
            key: str = os.environ.get("SUPABASE_SERVICE_KEY") or os.environ.get("SUPABASE_KEY")

            if not url or not key:
                raise RuntimeError(
                    "Supabase URL and Key could not be loaded. "
                    "Ensure you have a .env file in the project root with SUPABASE_URL and a service key."
                )

            # Configure client timeouts using nested options.
            options = ClientOptions(
                auth=AuthClientOptions(timeout=10),
                postgrest=PostgrestClientOptions(timeout=10),
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
