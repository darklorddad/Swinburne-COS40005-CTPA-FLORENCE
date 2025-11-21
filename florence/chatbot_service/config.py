"""
Configuration settings for the Florence Chatbot Microservice.
"""
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Supabase Configuration
    supabase_url: str
    supabase_service_key: str
    supabase_anon_key: str

    # DeepSeek AI Configuration
    deepseek_api_key: str
    deepseek_base_url: str = "https://api.deepseek.com/v1"
    deepseek_model: str = "deepseek-chat"
    deepseek_temperature: float = 0.8
    deepseek_max_tokens: int = 1000

    # Service Configuration
    service_host: str = "0.0.0.0"
    service_port: int = 8001

    # CORS Configuration
    cors_origins: list[str] = [
        "http://localhost:*",
        "http://127.0.0.1:*",
        "http://192.168.*.*:*",
    ]

    # Health Context Configuration
    health_context_days: int = 7
    health_context_cache_minutes: int = 5

    # Glucose Thresholds (mg/dL)
    glucose_low_threshold: float = 70.0
    glucose_high_threshold: float = 180.0
    glucose_target_min: float = 80.0
    glucose_target_max: float = 140.0

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False


# Global settings instance
settings = Settings()
