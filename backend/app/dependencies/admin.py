"""
Admin authorization dependency.
"""

from __future__ import annotations

from fastapi import Depends

from app.common.exceptions.forbidden import ForbiddenException
from app.dependencies.current_user import get_current_user
from app.modules.auth.model import User


async def get_current_admin(
    current_user: User = Depends(get_current_user),
) -> User:
    """
    Require the authenticated user to have admin privileges.
    """

    if current_user.role != "admin":
        raise ForbiddenException(
            "Admin access required."
        )

    return current_user
