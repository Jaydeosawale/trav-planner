from __future__ import annotations

from functools import lru_cache

from pydantic import Field, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict

from app.core.environment import CURRENT_ENVIRONMENT


class Settings(BaseSettings):
    """
    Global application settings.

    Single source of truth for the entire backend.
    """

    model_config = SettingsConfigDict(
        env_file=f".env.{CURRENT_ENVIRONMENT.value}",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ==========================================================
    # Application
    # ==========================================================

    APP_NAME: str = "Trav Planner API"

    APP_DESCRIPTION: str = (
        "Enterprise AI Multi-Agent Travel Planner Backend"
    )

    APP_VERSION: str = "1.0.0"

    ENVIRONMENT: str = CURRENT_ENVIRONMENT.value

    DEBUG: bool = False

    API_PREFIX: str = "/api/v1"

    # ==========================================================
    # Server
    # ==========================================================

    HOST: str = "0.0.0.0"

    PORT: int = 8000

    # ==========================================================
    # PostgreSQL
    # ==========================================================

    POSTGRES_HOST: str = "localhost"

    POSTGRES_PORT: int = 5432

    POSTGRES_DB: str = "travplanner"

    POSTGRES_USER: str = "travplanner_user"

    POSTGRES_PASSWORD: str = ""

    DATABASE_URL: str | None = None

    # ==========================================================
    # Redis
    # ==========================================================

    REDIS_HOST: str = "localhost"

    REDIS_PORT: int = 6379

    REDIS_PASSWORD: str = ""

    # ==========================================================
    # JWT
    # ==========================================================

    JWT_SECRET_KEY: str = Field(...)

    JWT_ALGORITHM: str = "HS256"

    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # ==========================================================
    # AI Platform
    # ==========================================================

    AI_PLATFORM_URL: str = "http://localhost:9000"

    # ==========================================================
    # API
    # ==========================================================

    API_TIMEOUT: int = 60

    # ==========================================================
    # Logging
    # ==========================================================

    LOG_LEVEL: str = "INFO"

    LOG_FILE: str = "logs/app.log"

    # ==========================================================
    # Uploads
    # ==========================================================

    MAX_UPLOAD_SIZE_MB: int = 50

    UPLOAD_FOLDER: str = "uploads"

    # ==========================================================
    # CORS
    # ==========================================================

    ALLOWED_ORIGINS: str = (
        "http://localhost:3000,"
        "http://localhost:5173,"
        "http://localhost:8080,"
        "http://localhost:8000,"
        "http://127.0.0.1:8000"
    )

    # ==========================================================
    # Computed Properties
    # ==========================================================

    @computed_field
    @property
    def allowed_origins(self) -> list[str]:
        """
        Returns allowed origins as a list.
        """
        return [
            origin.strip()
            for origin in self.ALLOWED_ORIGINS.split(",")
            if origin.strip()
        ]

    @computed_field
    @property
    def database_url(self) -> str:
        """
        Returns DATABASE_URL from environment if supplied.
        Otherwise builds it from POSTGRES_* variables.
        """

        if self.DATABASE_URL:
            return self.DATABASE_URL

        return (
            "postgresql+asyncpg://"
            f"{self.POSTGRES_USER}:"
            f"{self.POSTGRES_PASSWORD}@"
            f"{self.POSTGRES_HOST}:"
            f"{self.POSTGRES_PORT}/"
            f"{self.POSTGRES_DB}"
        )

    @computed_field
    @property
    def redis_url(self) -> str:
        """
        Redis connection URL.
        """

        if self.REDIS_PASSWORD:
            return (
                f"redis://:{self.REDIS_PASSWORD}@"
                f"{self.REDIS_HOST}:"
                f"{self.REDIS_PORT}"
            )

        return (
            f"redis://"
            f"{self.REDIS_HOST}:"
            f"{self.REDIS_PORT}"
        )

    @computed_field
    @property
    def is_production(self) -> bool:
        return self.ENVIRONMENT == "production"

    @computed_field
    @property
    def is_staging(self) -> bool:
        return self.ENVIRONMENT == "staging"

    @computed_field
    @property
    def is_development(self) -> bool:
        return self.ENVIRONMENT == "development"


@lru_cache
def get_settings() -> Settings:
    """
    Return cached settings instance.
    """
    return Settings()


settings = get_settings()