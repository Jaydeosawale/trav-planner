"""
City API v1 Router.
"""

from fastapi import APIRouter

from app.modules.city.router import router as city_router

router = APIRouter()

router.include_router(
    city_router,
    prefix="/cities",
    tags=["Cities"],
)