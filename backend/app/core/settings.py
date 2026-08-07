from functools import lru_cache
from app.core.environment import CURRENT_ENVIRONMENT

from pydantic import Field, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


# ---------------------------------------------------------
# Active Environment
# ---------------------------------------------------------



class Settings(BaseSettings):
    """
    Global application settings.

    This is the single source of truth for every configuration
    used across the backend.

    Supported environments:
    - development
    - staging
    - production
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

    APP_VERSION: str = "1.0.0"

    APP_DESCRIPTION: str = (
        "Enterprise AI Multi-Agent Travel Planner Backend"
    )


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

    POSTGRES_DB: str = "trav_planner"

    POSTGRES_USER: str = "postgres"

    POSTGRES_PASSWORD: str = "postgres"

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
    # API Configuration
    # ==========================================================

    API_TIMEOUT: int = 60

    # ==========================================================
    # Logging
    # ==========================================================

    LOG_LEVEL: str = "INFO"

    LOG_FILE: str = "logs/app.log"

    # ==========================================================
    # File Upload
    # ==========================================================

    MAX_UPLOAD_SIZE_MB: int = 50

    UPLOAD_FOLDER: str = "uploads"

    # ==========================================================
    # CORS
    # ==========================================================

    ALLOWED_ORIGINS: list[str] = [
        "http://localhost:3000",
        "http://localhost:5173",
        "http://localhost:8080",
        "http://localhost:8000",
    ]

    # ==========================================================
    # Computed Properties
    # ==========================================================

    @computed_field
    @property
    def DATABASE_URL(self) -> str:
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
    def REDIS_URL(self) -> str:
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
    def IS_PRODUCTION(self) -> bool:
        return self.ENVIRONMENT == "production"

    @computed_field
    @property
    def IS_STAGING(self) -> bool:
        return self.ENVIRONMENT == "staging"

    @computed_field
    @property
    def IS_DEVELOPMENT(self) -> bool:
        return self.ENVIRONMENT == "development"


@lru_cache
def get_settings() -> Settings:
    """
    Cached settings instance.
    """
    return Settings()


settings = get_settings()