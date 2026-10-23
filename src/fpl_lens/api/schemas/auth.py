import re

from pydantic import BaseModel, ConfigDict, Field, field_validator


class StrictBaseModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class RegisterRequest(StrictBaseModel):
    email: str = Field(..., max_length=255)
    password: str = Field(..., min_length=8, max_length=128)
    display_name: str = Field(..., min_length=1, max_length=64)
    fpl_team_id: int = Field(..., gt=0, lt=20_000_000)

    @field_validator("email")
    @classmethod
    def validate_email_format(cls, v: str) -> str:
        v = v.strip().lower()
        if not re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", v):
            raise ValueError("Invalid email format")
        return v


class LoginRequest(StrictBaseModel):
    email: str
    password: str

    @field_validator("email")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return v.strip().lower()


class VerifyEmailRequest(StrictBaseModel):
    code: str = Field(..., min_length=6, max_length=6)

    @field_validator("code")
    @classmethod
    def validate_code(cls, v: str) -> str:
        v = v.strip()
        if not v.isdigit():
            raise ValueError("Code must be 6 numeric digits")
        return v


class GoogleAuthRequest(StrictBaseModel):
    id_token: str
    fpl_team_id: int | None = Field(default=None, gt=0, lt=20_000_000)


class RefreshRequest(StrictBaseModel):
    refresh_token: str


class ForgotPasswordRequest(StrictBaseModel):
    email: str

    @field_validator("email")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return v.strip().lower()


class ResetPasswordRequest(StrictBaseModel):
    email: str
    code: str = Field(..., min_length=6, max_length=6)
    new_password: str = Field(..., min_length=8, max_length=128)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return v.strip().lower()

    @field_validator("code")
    @classmethod
    def validate_code(cls, v: str) -> str:
        v = v.strip()
        if not v.isdigit():
            raise ValueError("Code must be 6 numeric digits")
        return v


class TokenResponse(StrictBaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "Bearer"
    expires_in: int = 900


class UserProfileResponse(StrictBaseModel):
    id: str
    email: str | None
    display_name: str | None
    fpl_team_id: int
    status: str
    created_at: str


class NotificationPreferencesRequest(StrictBaseModel):
    deadline_reminders: bool = True
    injury_alerts: bool = True
    deadline_reminder_hours: int = Field(default=6)

    @field_validator("deadline_reminder_hours")
    @classmethod
    def validate_hours(cls, v: int) -> int:
        if v not in (1, 3, 6, 12, 24):
            raise ValueError("deadline_reminder_hours must be one of 1, 3, 6, 12, 24")
        return v


class NotificationPreferencesResponse(StrictBaseModel):
    deadline_reminders: bool
    injury_alerts: bool
    deadline_reminder_hours: int
