"""
Application metadata and API configuration.
"""

from __future__ import annotations

from dataclasses import dataclass

from app.core.settings import settings


@dataclass(frozen=True)
class APIConfig:
    """Application API configuration."""

    title: str = settings.APP_NAME
    description: str = settings.APP_DESCRIPTION
    version: str = settings.APP_VERSION

    openapi_url: str = f"{settings.API_PREFIX}/openapi.json"

    docs_url: str = "/docs"

    redoc_url: str = "/redoc"

    openapi_tags = [
        {
            "name": "Health",
            "description": "Application health endpoints",
        },
        {
            "name": "Authentication",
            "description": "Authentication and authorization",
        },
        {
            "name": "Home",
            "description": "Dynamic home screen APIs",
        },
        {
            "name": "Planner",
            "description": "AI Travel Planner",
        },
        {
            "name": "Booking",
            "description": "Bookings and reservations",
        },
    ]


api_config = APIConfig()