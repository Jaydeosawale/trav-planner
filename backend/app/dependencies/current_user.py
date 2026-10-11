"""
Current authenticated user dependency.
"""

from __future__ import annotations

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.common.exceptions.forbidden import ForbiddenException
from app.common.exceptions.unauthorized import UnauthorizedException
from app.common.security.jwt import decode_access_token
from app.database.session import get_db
from app.dependencies.auth import get_bearer_token
from app.modules.auth.model import User
from app.modules.auth.repository import UserRepository


user_repository = UserRepository()


async def get_current_user(
    token: str = Depends(get_bearer_token),
    db: AsyncSession = Depends(get_db),
) -> User:
    """
    Resolve the authenticated user from the JWT access token.
    """

    try:
        payload = decode_access_token(token)
    except ValueError as exc:
        raise UnauthorizedException(
            "Invalid or expired access token."
        ) from exc

    user_id = payload.get("sub")

    if not user_id:
        raise UnauthorizedException(
            "Invalid access token."
        )

    user = await user_repository.get_by_id(
        db,
        user_id,
    )

    if user is None:
        raise UnauthorizedException(
            "Authenticated user not found."
        )

    if payload.get("ver", 0) != user.auth_version:
        raise UnauthorizedException("Your session expired. Please sign in again.")

    if not user.is_active:
        raise ForbiddenException(
            "User account is inactive."
        )

    return user