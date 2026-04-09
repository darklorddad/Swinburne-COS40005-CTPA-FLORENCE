## This file defines the configuration settings for the Recommendations feature of the LLM Engine Service. It uses Pydantic's BaseSettings to load environment variables, allowing for easy configuration of the LLM model and max tokens used specifically for generating recommendations. This separation ensures that changes to recommendation settings do not affect other features like the chatbot or nutrition service.

## This is also just a temporary config file for the Recommendations feature. In a larger application, this project have the a bigger oppurtunity to have a more centralized configuration management system, but for this project, this approach keeps things simple and modular for testing and development purposes.

from pathlib import Path
from typing import Optional
from pydantic_settings import BaseSettings

class RecommendationSettings(BaseSettings):
    # Optional override — if unset, service.py falls back to global LLM_MODEL (same as nutrition)
    LLM_MODEL: Optional[str] = None
    LLM_MAX_TOKENS: int = 4096  # increased to prevent truncated JSON on detailed responses

    class Config:
        _env_file = Path(__file__).resolve().parent.parent.parent.parent / ".env"
        env_file = _env_file if _env_file.exists() else None
        env_file_encoding = "utf-8"
        extra = "ignore"

recommendation_settings = RecommendationSettings()
