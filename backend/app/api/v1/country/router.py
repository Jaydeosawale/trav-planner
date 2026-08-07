"""
Country API v1 Router.
"""

from fastapi import APIRouter

from app.modules.country.router import router as country_router

router = APIRouter()

router.include_router(
    country_router,
    prefix="/countries",
    tags=["Countries"],
)