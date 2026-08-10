"""
Authentication module router.
"""

from __future__ import annotations

from fastapi import APIRouter
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.responses.api_response import success_response
from app.database.session import get_db
from app.dependencies.current_user import get_current_user
from app.modules.auth.model import User
from app.modules.auth.schema import LoginRequest
from app.modules.auth.schema import RegisterRequest
from app.modules.auth.schema import TokenResponse
from app.modules.auth.schema import UserResponse
from app.modules.auth.service import AuthService
from app.modules.auth.schema import RefreshTokenRequest


router = APIRouter()

service = AuthService()


# ==========================================================
# Register
# ==========================================================

@router.post(
    "/register",
    summary="Register a new user",
)
async def register(
    payload: RegisterRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Register a new user.
    """

    user = await service.register(
        db,
        payload,
    )

    return success_response(
        data=UserResponse.model_validate(user),
        message="User registered successfully",
    )


# ==========================================================
# Login
# ==========================================================

@router.post(
    "/login",
    summary="Login user",
)
async def login(
    payload: LoginRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Authenticate a user and return access
    and refresh tokens.
    """

    result = await service.authenticate(
        db,
        payload,
    )

    return success_response(
        data=TokenResponse.model_validate(result),
        message="Login successful",
    )


# ==========================================================
# Current User
# ==========================================================

@router.get(
    "/me",
    summary="Get current authenticated user",
)
async def get_me(
    current_user: User = Depends(get_current_user),
):
    """
    Return the currently authenticated user.
    """

    return success_response(
        data=UserResponse.model_validate(current_user),
        message="Current user retrieved successfully",
    )

# ==========================================================
# Refresh Token
# ==========================================================

@router.post(
    "/refresh",
    summary="Refresh access token",
)
async def refresh_token(
    payload: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Generate a new access token using a refresh token.
    """

    result = await service.refresh_access_token(
        db,
        payload,
    )

    return success_response(
        data=TokenResponse.model_validate(result),
        message="Access token refreshed successfully",
    )    