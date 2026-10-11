"""
Authentication schemas.
"""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel
from pydantic import ConfigDict
from pydantic import EmailStr
from pydantic import Field


# ==========================================================
# Register
# ==========================================================

class RegisterRequest(BaseModel):
    """
    User registration payload.
    """

    email: EmailStr

    password: str = Field(
        min_length=8,
        max_length=128,
    )

    full_name: str = Field(
        min_length=2,
        max_length=150,
    )


# ==========================================================
# Login
# ==========================================================

class LoginRequest(BaseModel):
    """
    User login payload.
    """

    email: EmailStr

    password: str = Field(
        min_length=8,
        max_length=128,
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