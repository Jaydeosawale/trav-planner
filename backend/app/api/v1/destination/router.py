"""
Destination API v1 Router.
"""

from fastapi import APIRouter

from app.modules.destination.router import router as destination_router

router = APIRouter()

router.include_router(
     destination_router,
    tags=["Destinations"],
)