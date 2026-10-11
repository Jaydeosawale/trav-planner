"""
Itinerary API v1 router.
"""

from fastapi import APIRouter

from app.modules.itinerary.router import router as itinerary_module_router


router = APIRouter()

router.include_router(
    itinerary_module_router,
)
