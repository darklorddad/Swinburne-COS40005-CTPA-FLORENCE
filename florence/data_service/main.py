# main.py
import os
import logging
from fastapi import FastAPI, Depends, HTTPException, Header, Request
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional, Dict, Any

# Import the router from your new authentication file
from .routers import authentication, patients, clinicians, admin
# Import the Supabase client from its dedicated file
from .routers.authentication import get_current_admin_user

app = FastAPI()

# Configure logging
logging.basicConfig(
    level=os.environ.get("LOG_LEVEL", "INFO"),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Get allowed origins from environment variable, default to allowing all.
# The env var should be a comma-separated string of URLs, e.g., "http://localhost:3000,https://my-app.com"
allowed_origins_str = os.environ.get("CORS_ALLOWED_ORIGINS", "*")
allowed_origins = [origin.strip() for origin in allowed_origins_str.split(',')]

# Add CORS middleware to allow requests from the Flutter web app
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

# Include the authentication router in your main application
app.include_router(authentication.router)
app.include_router(patients.router)
app.include_router(clinicians.router)
app.include_router(admin.router)


