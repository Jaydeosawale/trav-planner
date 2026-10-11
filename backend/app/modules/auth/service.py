"""
Authentication service.
"""

from __future__ import annotations

from app.common.security.passwords import hash_password, verify_password
from app.common.exceptions.unauthorized import UnauthorizedException
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.constants.not_found import NotFoundException
from app.common.exceptions.conflict import ConflictException
from app.common.security.jwt import create_access_token
from app.common.security.jwt import create_refresh_token
from app.common.security.jwt import decode_refresh_token
from app.modules.auth.model import User
from app.modules.auth.repository import UserRepository
from app.modules.auth.schema import LoginRequest
from app.modules.auth.schema import RefreshTokenRequest
from app.modules.auth.schema import RegisterRequest
from app.modules.auth.schema import TokenResponse


class AuthService:
    """
    Authentication business logic.
    """

    def __init__(self) -> None:
        self.repository = UserRepository()


    # ==========================================================
    # Register
    # ==========================================================

    async def register(
        self,
        db: AsyncSession,
        payload: RegisterRequest,
    ) -> User:
        """
        Register a new user.
        """

        existing_user = await self.repository.get_by_email(
            db,
            payload.email,
        )

        if existing_user is not None:
            raise ConflictException(
                "A user with this email already exists."
            )

        user = User(
            email=payload.email,
            password_hash=hash_password(
                payload.password,
            ),
            full_name=payload.full_name,
        )

        user = await self.repository.create(
            db,
            user,
        )

        await db.commit()

        return user

    # ==========================================================
    # Login
    # ==========================================================

    async def authenticate(
        self,
        db: AsyncSession,
        payload: LoginRequest,
    ) -> TokenResponse:
        """
        Authenticate a user and generate access
        and refresh tokens.
        """

        user = await self.repository.get_by_email(
            db,
            payload.email,
        )

        if user is None:
            raise UnauthorizedException("Invalid email or password.")

        if not user.is_active:
            raise ConflictException(
                "User account is inactive."
            )

        password_valid = verify_password(
            payload.password,
            user.password_hash,
        )

        if not password_valid:
            raise UnauthorizedException("Invalid email or password.")

        # ------------------------------------------------------
        # Access Token
        # ------------------------------------------------------

        access_token = create_access_token(
            user_id=user.id,
            auth_version=user.auth_version,
        )

        # ------------------------------------------------------
        # Refresh Token
        # ------------------------------------------------------

        refresh_token = create_refresh_token(
            user_id=user.id,
            auth_version=user.auth_version,
        )

        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
        )

    # ==========================================================
    # Refresh Access Token
    # ==========================================================

    async def refresh_access_token(
        self,
        db: AsyncSession,
        payload: RefreshTokenRequest,
    ) -> TokenResponse:
        """
        Generate a new access token using a refresh token.
        """

        try:
            token_payload = decode_refresh_token(
                payload.refresh_token,
            )
        except ValueError:
            raise ConflictException(
                "Invalid or expired refresh token."
            )

        user_id = token_payload.get("sub")

        if not user_id:
            raise ConflictException(
                "Invalid refresh token."
            )

        user = await self.repository.get_by_id(
            db,
            user_id,
        )

        if user is None:
            raise NotFoundException("User")

        if not user.is_active or token_payload.get('ver', 0) != user.auth_version:
            raise UnauthorizedException("Invalid or expired refresh token.")

        access_token = create_access_token(
            user_id=user.id,
            auth_version=user.auth_version,
        )

        return TokenResponse(
            access_token=access_token,
            refresh_token=payload.refresh_token,
            token_type="bearer",
        )
