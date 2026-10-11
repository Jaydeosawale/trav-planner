"""
Authentication schemas.
"""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel
from pydantic import ConfigDict
from pydantic import EmailStr
from pydantic import Field, field_validator


# ==========================================================
# Register
# ==========================================================

class Credentials(BaseModel):
    @field_validator('email', check_fields=False)
    @classmethod
    def normalize_email(cls, value):
        return value.strip().lower()

    @field_validator('password', check_fields=False)
    @classmethod
    def validate_password_bytes(cls, value):
        if len(value.encode('utf-8')) > 72:
            raise ValueError('Password must be no more than 72 UTF-8 bytes.')
        return value


class RegisterRequest(Credentials):
    """
    User registration payload.
    """

    email: EmailStr

    password: str = Field(
        min_length=8,
        max_length=72,
    )

    full_name: str = Field(
        min_length=2,
        max_length=150,
    )


# ==========================================================
# Login
# ==========================================================

class LoginRequest(Credentials):
    """
    User login payload.
    """

    email: EmailStr

    password: str = Field(
        min_length=8,
        max_length=72,
    )


# ==========================================================
# User Response
# ==========================================================

class UserResponse(BaseModel):
    """
    Public user representation.
    """

    model_config = ConfigDict(
        from_attributes=True,
    )

    id: str
    email: EmailStr
    full_name: str
    is_active: bool
    created_at: datetime
    role: str

# ==========================================================
# Refresh Token Request
# ==========================================================

class RefreshTokenRequest(BaseModel):
    """
    Refresh token request payload.
    """

    refresh_token: str


# ==========================================================
# Token Response
# ==========================================================

class TokenResponse(BaseModel):
    """
    JWT token response.
    """

    access_token: str

    refresh_token: str

    token_type: str = "bearer"

class PasswordResetRequest(Credentials):
    email: EmailStr


class PasswordResetConfirm(Credentials):
    token: str = Field(min_length=40, max_length=128)
    password: str = Field(min_length=8, max_length=72)
