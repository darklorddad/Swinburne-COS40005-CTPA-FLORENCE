import os
import httpx
from pathlib import Path
from supabase import create_client, Client, ClientOptions
from dotenv import load_dotenv

# Load environment variables from .env file in the project root.
# This ensures that the .env file is found regardless of the current working directory.
project_root = Path(__file__).resolve().parent.parent
load_dotenv(dotenv_path=project_root / '.env')

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_KEY")

# To resolve the deprecation warnings, we configure the timeout and other
# connection settings directly on an httpx.Client and pass it to Supabase.
# This is the modern, future-compatible approach.
options = ClientOptions(
    httpx_client=httpx.Client(timeout=10.0)
)

supabase: Client = create_client(url, key, options=options)
