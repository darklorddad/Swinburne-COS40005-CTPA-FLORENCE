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

    # DeepSeek AI Configuration
    deepseek_api_key: str
    deepseek_base_url: str = "https://api.deepseek.com/v1"
    deepseek_model: str = "deepseek-chat"
    deepseek_temperature: Optional[float] = None
    deepseek_max_tokens: Optional[int] = None

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

    # Health Context Configuration
    health_context_days: int = 28
    health_context_cache_minutes: int = 5

    # Glucose Thresholds (mg/dL)
    glucose_low_threshold: float = 70.0
    glucose_high_threshold: float = 180.0
    glucose_target_min: float = 80.0
    glucose_target_max: float = 140.0

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
