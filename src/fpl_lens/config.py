import os
from pathlib import Path

from dotenv import load_dotenv
from pydantic import Field
from pydantic_settings import BaseSettings

# Load local .env if present
load_dotenv()


def resolve_secret_ref(ref_or_val: str | None) -> str | None:
    """
    Resolves secret values that may be references (*_REF).
    If the value points to an existing file path, read and return the file content.
    If the value names another environment variable in os.environ, return that variable's value.
    Otherwise, return the string as-is.
    """
    if not ref_or_val:
        return None
    try:
        p = Path(ref_or_val)
        if p.exists() and p.is_file():
            return p.read_text(encoding="utf-8").strip()
    except (OSError, ValueError):
        pass

    if ref_or_val in os.environ:
        return os.environ[ref_or_val]

    return ref_or_val


class Settings(BaseSettings):
    # Environment & Host
    ENV: str = Field(default="production", validation_alias="ENV")
    LOG_LEVEL: str = Field(default="INFO", validation_alias="LOG_LEVEL")
    PORT: int = Field(default=8000, validation_alias="PORT")

    # Database
    DATABASE_URL: str = Field(
        default="postgresql://localhost:5432/fpl_lens",
        validation_alias="DATABASE_URL",
    )
    DATABASE_URL_POOLED: str | None = Field(
        default=None,
        validation_alias="DATABASE_URL_POOLED",
    )
    DATABASE_URL_REF: str | None = Field(
        default=None,
        validation_alias="DATABASE_URL_REF",
    )

    # Upstream FPL API
    FPL_BASE_URL: str = Field(
        default="https://fantasy.premierleague.com",
        validation_alias="FPL_BASE_URL",
    )
    FPL_USER_AGENT: str = Field(
        default="FPLLens/0.1 (+https://github.com/Kena-AT/FPL_Lens)",
        validation_alias="FPL_USER_AGENT",
    )
    FPL_GLOBAL_THROTTLE_RPS: float = Field(
        default=3.0,
        validation_alias="FPL_GLOBAL_THROTTLE_RPS",
    )
    FPL_BOOTSTRAP_THROTTLE_SECONDS: int = Field(
        default=600,
        validation_alias="FPL_BOOTSTRAP_THROTTLE_SECONDS",
    )
    FPL_HISTORY_THROTTLE_RPS: float = Field(
        default=5.0,
        validation_alias="FPL_HISTORY_THROTTLE_RPS",
    )
    FPL_CACHE_TTL_SECONDS: int = Field(
        default=600,
        validation_alias="FPL_CACHE_TTL_SECONDS",
    )
    FPL_ENTRY_CACHE_TTL_SECONDS: int = Field(
        default=3600,
        validation_alias="FPL_ENTRY_CACHE_TTL_SECONDS",
    )

    # Auth & Tokens
    JWT_SIGNING_KEY: str | None = Field(default=None, validation_alias="JWT_SIGNING_KEY")
    JWT_SIGNING_KEY_REF: str | None = Field(default=None, validation_alias="JWT_SIGNING_KEY_REF")
    JWT_PREVIOUS_KEY: str | None = Field(default=None, validation_alias="JWT_PREVIOUS_KEY")
    JWT_PREVIOUS_KEY_REF: str | None = Field(default=None, validation_alias="JWT_PREVIOUS_KEY_REF")
    JWT_ISSUER: str = Field(default="fpl-lens-api", validation_alias="JWT_ISSUER")
    JWT_AUDIENCE: str = Field(default="fpl-lens-client", validation_alias="JWT_AUDIENCE")
    ACCESS_TOKEN_TTL_SECONDS: int = Field(default=900, validation_alias="ACCESS_TOKEN_TTL_SECONDS")
    REFRESH_TOKEN_TTL_DAYS: int = Field(default=30, validation_alias="REFRESH_TOKEN_TTL_DAYS")

    # Google Auth
    GOOGLE_ANDROID_CLIENT_ID: str | None = Field(
        default=None,
        validation_alias="GOOGLE_ANDROID_CLIENT_ID",
    )
    GOOGLE_WEB_CLIENT_ID: str | None = Field(
        default=None,
        validation_alias="GOOGLE_WEB_CLIENT_ID",
    )
    GOOGLE_WEB_CLIENT_SECRET: str | None = Field(
        default=None,
        validation_alias="GOOGLE_WEB_CLIENT_SECRET",
    )

    # SMTP (Brevo)
    SMTP_HOST: str = Field(default="smtp-relay.brevo.com", validation_alias="SMTP_HOST")
    SMTP_PORT: int = Field(default=587, validation_alias="SMTP_PORT")
    SMTP_USERNAME: str | None = Field(default=None, validation_alias="SMTP_USERNAME")
    SMTP_PASSWORD: str | None = Field(default=None, validation_alias="SMTP_PASSWORD")
    SMTP_USER_REF: str | None = Field(default=None, validation_alias="SMTP_USER_REF")
    SMTP_PASSWORD_REF: str | None = Field(default=None, validation_alias="SMTP_PASSWORD_REF")
    EMAIL_FROM_ADDRESS: str = Field(
        default="noreply@fpl-lens.app",
        validation_alias="EMAIL_FROM_ADDRESS",
    )

    # FCM / Push
    FIREBASE_CREDENTIALS_PATH: str | None = Field(
        default=None,
        validation_alias="FIREBASE_CREDENTIALS_PATH",
    )
    FCM_SERVICE_ACCOUNT_REF: str | None = Field(
        default=None,
        validation_alias="FCM_SERVICE_ACCOUNT_REF",
    )

    # Internal Jobs Token
    JOB_TOKEN: str | None = Field(default=None, validation_alias="JOB_TOKEN")
    JOB_TOKEN_REF: str | None = Field(default=None, validation_alias="JOB_TOKEN_REF")

    model_config = {
        "extra": "ignore",
        "case_sensitive": False,
    }

    def get_effective_database_url(self, pooled: bool = True) -> str:
        """
        Returns the resolved database URL.
        Resolves *_REF if specified. Prefers pooled connection string when pooled=True.
        Normalizes postgresql:// to postgresql+psycopg2:// for SQLAlchemy.
        """
        raw_url = None
        if self.DATABASE_URL_REF:
            resolved = resolve_secret_ref(self.DATABASE_URL_REF)
            if resolved:
                raw_url = resolved

        if not raw_url and pooled and self.DATABASE_URL_POOLED:
            raw_url = self.DATABASE_URL_POOLED

        if not raw_url:
            raw_url = self.DATABASE_URL

        if raw_url.startswith("postgresql://"):
            raw_url = raw_url.replace("postgresql://", "postgresql+psycopg2://", 1)
        elif raw_url.startswith("postgres://"):
            raw_url = raw_url.replace("postgres://", "postgresql+psycopg2://", 1)

        return raw_url

    def get_effective_job_token(self) -> str:
        if self.JOB_TOKEN_REF:
            resolved = resolve_secret_ref(self.JOB_TOKEN_REF)
            if resolved:
                return resolved
        return self.JOB_TOKEN or "dev-job-token-fpl-lens-default-64-bytes"

    def get_effective_jwt_signing_key(self) -> str:
        if self.JWT_SIGNING_KEY_REF:
            resolved = resolve_secret_ref(self.JWT_SIGNING_KEY_REF)
            if resolved:
                return resolved
        return self.JWT_SIGNING_KEY or "dev-secret-signing-key-fpl-lens-32-chars-long"

    def get_effective_jwt_previous_key(self) -> str | None:
        if self.JWT_PREVIOUS_KEY_REF:
            resolved = resolve_secret_ref(self.JWT_PREVIOUS_KEY_REF)
            if resolved:
                return resolved
        return self.JWT_PREVIOUS_KEY

    def get_effective_smtp_password(self) -> str | None:
        if self.SMTP_PASSWORD_REF:
            resolved = resolve_secret_ref(self.SMTP_PASSWORD_REF)
            if resolved:
                return resolved
        return self.SMTP_PASSWORD


settings = Settings()
