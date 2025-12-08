import os
from pathlib import Path
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # API Config
    PROJECT_NAME: str = "Florence LLM Engine"
    
    # LLM Configuration
    # Vercel will inject these from Project Settings
    LLM_API_KEY: str
    LLM_BASE_URL: str = "https://openrouter.ai/api/v1"
    
    # Using a fast model to avoid Vercel 10s timeout on Hobby plan
    # Gemini Flash is multimodal (sees images) and very fast
    LLM_MODEL: str = "google/gemini-2.0-flash-lite-preview-02-05:free" 
    
    class Config:
        # Load from ../../.env for local dev
        # Vercel ignores this if file is missing and uses Environment Variables
        env_file = Path(__file__).resolve().parent.parent.parent / ".env"
        env_file_encoding = "utf-8"
        extra = "ignore" 

settings = Settings()
