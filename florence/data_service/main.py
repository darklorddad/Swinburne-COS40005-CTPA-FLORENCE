# main.py
import os
import logging
import time
from fastapi import FastAPI, Depends, HTTPException, Header, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from typing import Optional, Dict, Any

# Import the router from your new authentication file
from .routers import authentication, patients, clinicians, admin
# The get_current_admin_user dependency is used within the authentication router,
# so there is no need to import it here directly.

app = FastAPI()

# Add this middleware to log all requests and catch any unhandled exceptions
@app.middleware("http")
async def log_requests_and_handle_errors(request: Request, call_next):
    """
    Middleware to log requests, add a process time header, and
    catch unhandled server errors to ensure a JSON 500 response.
    """
    start_time = time.time()
    try:
        response = await call_next(request)
        process_time = time.time() - start_time
        response.headers["X-Process-Time"] = f"{process_time:.4f}s"
        logging.info(f'Request: {request.method} {request.url.path} - Status: {response.status_code}')
        return response
    except Exception:
        process_time = time.time() - start_time
        logging.error(
            f"Unhandled exception for request {request.method} {request.url.path} after {process_time:.4f}s",
            exc_info=True # This will log the full traceback
        )
        return JSONResponse(
            status_code=500,
            content={"detail": "An internal server error occurred."},
        )


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


