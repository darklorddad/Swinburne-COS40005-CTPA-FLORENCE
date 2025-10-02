import os
import httpx
from supabase import create_client, Client, ClientOptions
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_KEY")

# To resolve the deprecation warnings, we configure the timeout and other
# connection settings directly on an httpx.Client and pass it to Supabase.
# This is the modern, future-compatible approach.
options = ClientOptions(
    http_client=httpx.Client(timeout=10.0)
)

supabase: Client = create_client(url, key, options=options)
