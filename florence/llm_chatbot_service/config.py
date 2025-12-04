"""
Configuration settings for the Florence Chatbot Microservice.
"""
from pathlib import Path
from pydantic_settings import BaseSettings
from typing import Optional
import os


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Data Service Configuration
    data_service_url: str = "https://ds-florence-dhp.vercel.app"

    # OpenRouter Configuration (Temporarily replacing DeepSeek)
    openrouter_api_key: str
    openrouter_base_url: str = "https://openrouter.ai/api/v1"
    openrouter_model: str = "google/gemini-3-pro-preview"
    openrouter_temperature: Optional[float] = None
    openrouter_max_tokens: Optional[int] = None

    # Service Configuration
    service_host: str = "0.0.0.0"
    service_port: int = 8001

    # CORS Configuration
    cors_origins: list[str] = [
        "http://localhost:*",
        "http://127.0.0.1:*",
        "http://192.168.*.*:*",
        "https://*.vercel.app",
        "*",  # Allow all origins for mobile app access
    ]


    class Config:
        # Resolve the path to the .env file in the project root
        # Current file: florence/chatbot_service/config.py
        # Root .env:    ../../.env (relative to florence folder)
        _env_file_path = Path(__file__).resolve().parent.parent.parent / ".env"
        
        # Only use the .env file if it exists (Local Development)
        # In Production (Vercel), environment variables are injected directly
        if _env_file_path.exists():
            env_file = _env_file_path
            
        env_file_encoding = "utf-8"
        case_sensitive = False
        extra = "ignore"


# Global settings instance
settings = Settings()
