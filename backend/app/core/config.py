import json
from typing import List, Optional, Union
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Application Settings loaded from environment variables or .env file.
    """
    PROJECT_NAME: str = "Second Brain API"
    ENVIRONMENT: str = "development"
    API_PREFIX: str = "/api/v1"
    PORT: int = 8000
    TESTING: bool = False

    # Database Settings - ONLY PostgreSQL allowed
    DATABASE_URL: str = "postgresql+psycopg://postgres:postgres@localhost:5432/second_brain"

    # Firebase Authentication Configuration
    FIREBASE_CREDENTIALS_PATH: Optional[str] = None
    FIREBASE_PROJECT_ID: Optional[str] = None
    FIREBASE_CLIENT_EMAIL: Optional[str] = None
    FIREBASE_PRIVATE_KEY: Optional[str] = None
    FIREBASE_DEV_MODE: bool = True
    DEV_MODE_ENABLED: Optional[bool] = None
    DEV_USER_EMAIL: str = "dev@secondbrain.app"
    DEV_USER_UID: str = "dev-user-001"

    # API Documentation toggle
    ENABLE_DOCS: Optional[bool] = None

    @property
    def is_dev_mode(self) -> bool:
        """
        Determines whether development mode is active.
        If DEV_MODE_ENABLED is explicitly set, it takes precedence.
        In production (ENVIRONMENT == 'production'), dev mode is strictly False
        unless DEV_MODE_ENABLED=True is explicitly set.
        Otherwise falls back to FIREBASE_DEV_MODE.
        """
        if self.DEV_MODE_ENABLED is not None:
            return self.DEV_MODE_ENABLED
        if self.ENVIRONMENT == "production":
            return False
        return self.FIREBASE_DEV_MODE

    # CORS Settings
    CORS_ORIGINS: Union[List[str], str] = [
        "http://localhost",
        "http://localhost:8080",
        "http://localhost:3000",
        "http://127.0.0.1",
        "http://10.0.2.2",  # Android emulator localhost alias
    ]

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",") if i.strip()]
        elif isinstance(v, str) and v.startswith("["):
            return json.loads(v)
        return v

    @field_validator("DATABASE_URL")
    @classmethod
    def validate_postgresql_only(cls, v: str) -> str:
        """
        Enforce architectural decision: Only PostgreSQL is allowed.
        Fails fast if SQLite or other databases are attempted.
        Automatically normalizes 'postgres://' or 'postgresql://' to 'postgresql+psycopg://'
        for seamless cloud deployment on Render, Neon, Supabase, and Railway.
        """
        if v.startswith("postgres://"):
            v = v.replace("postgres://", "postgresql+psycopg://", 1)
        elif v.startswith("postgresql://") and not v.startswith("postgresql+psycopg://"):
            v = v.replace("postgresql://", "postgresql+psycopg://", 1)

        if not (v.startswith("postgresql://") or v.startswith("postgresql+psycopg://")):
            raise ValueError(
                "Second Brain strictly requires PostgreSQL. SQLite or other local DBs are forbidden. "
                "DATABASE_URL must begin with 'postgresql+psycopg://' or 'postgresql://'."
            )
        return v

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )


settings = Settings()
