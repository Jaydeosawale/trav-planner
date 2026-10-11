"""Public place catalogue endpoints."""

from fastapi import APIRouter

from app.modules.place.router import router as place_router

router = APIRouter()

router.include_router(
    place_router,
    tags=["Places"],
)
