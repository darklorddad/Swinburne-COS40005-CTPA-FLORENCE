# main.py
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Import the routers
from routers import authentication, patients, clinicians, admin, chat_history

app = FastAPI(
    title="Florence Data Service",
    description="Backend API for Florence Digital Health Platform",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Add CORS middleware to allow requests from the Flutter web app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

# Include the routers
app.include_router(authentication.router)
app.include_router(patients.router)
app.include_router(clinicians.router)
app.include_router(admin.router)
app.include_router(chat_history.router)

@app.get("/")
def root():
    """
    Root endpoint for health checks and service verification.
    """
    return {
        "service": "Florence Data Service",
        "status": "operational",
        "version": "1.0.0"
    }
