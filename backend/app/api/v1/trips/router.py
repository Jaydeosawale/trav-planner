"""
Trip API v1 router.
"""

from fastapi import APIRouter

from app.modules.trips.router import router as trips_module_router


router = APIRouter()

router.include_router(
    trips_module_router,
)
