"""
Authentication dependencies.
"""

from __future__ import annotations

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials
from fastapi.security import HTTPBearer


bearer_scheme = HTTPBearer()


async def get_bearer_token(
    credentials: HTTPAuthorizationCredentials = Depends(
        bearer_scheme,
    ),
) -> str:
    """
    Extract the JWT bearer token from the Authorization header.
    """

    return credentials.credentials