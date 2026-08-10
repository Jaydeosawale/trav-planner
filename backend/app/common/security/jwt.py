"""
JWT authentication utilities.
"""

from __future__ import annotations

from datetime import datetime
from datetime import timedelta
from datetime import timezone

from jose import JWTError
from jose import jwt

from app.core.settings import settings


# ==========================================================
# Access Token
# ==========================================================

def create_access_token(
    user_id: str,
) -> str:
    """
    Create a short-lived JWT access token.
    """

    now = datetime.now(timezone.utc)

    expire = now + timedelta(
        minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES,
    )

    payload = {
        "sub": user_id,
        "type": "access",
        "iat": now,
        "exp": expire,
    }

    return jwt.encode(
        payload,
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM,
    )


# ==========================================================
# Refresh Token
# ==========================================================

def create_refresh_token(
    user_id: str,
) -> str:
    """
    Create a long-lived JWT refresh token.
    """

    now = datetime.now(timezone.utc)

    expire = now + timedelta(
        days=settings.REFRESH_TOKEN_EXPIRE_DAYS,
    )

    payload = {
        "sub": user_id,
        "type": "refresh",
        "iat": now,
        "exp": expire,
    }

    return jwt.encode(
        payload,
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM,
    )


# ==========================================================
# Decode Access Token
# ==========================================================

def decode_access_token(
    token: str,
) -> dict:
    """
    Decode and validate an access token.
    """

    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
        )

        if payload.get("type") != "access":
            raise JWTError("Invalid token type")

        if not payload.get("sub"):
            raise JWTError("Missing subject")

        return payload

    except JWTError as exc:
        raise ValueError(
            "Invalid or expired access token"
        ) from exc


# ==========================================================
# Decode Refresh Token
# ==========================================================

def decode_refresh_token(
    token: str,
) -> dict:
    """
    Decode and validate a refresh token.
    """

    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
        )

        if payload.get("type") != "refresh":
            raise JWTError("Invalid token type")

        if not payload.get("sub"):
            raise JWTError("Missing subject")

        return payload

    except JWTError as exc:
        raise ValueError(
            "Invalid or expired refresh token"
        ) from exc