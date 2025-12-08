import os
from pathlib import Path
from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    PROJECT_NAME: str = "Florence LLM Engine"
    APP_ENV: str = "development" # development, preview, production
    
    # --- Integration Configuration ---
    DATA_SERVICE_URL: str = "http://localhost:8000"

    # --- LLM Configuration ---
    # Vercel will inject these in Prod/Preview. Local uses .env
    LLM_API_KEY: str
    LLM_BASE_URL: str = "https://openrouter.ai/api/v1"
    LLM_MODEL: str = "google/gemini-2.0-flash-lite-preview-02-05:free"
    LLM_TEMPERATURE: Optional[float] = None
    LLM_MAX_TOKENS: Optional[int] = None
    
    class Config:
        # Load from repo root .env for local dev
        _env_file = Path(__file__).resolve().parent.parent.parent / ".env"
        env_file = _env_file if _env_file.exists() else None
        env_file_encoding = "utf-8"
        extra = "ignore"

settings = Settings()
