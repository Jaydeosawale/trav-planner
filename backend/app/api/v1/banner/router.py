from fastapi import APIRouter

from app.modules.banner.router import router as banner_router

router = APIRouter()

router.include_router(
    banner_router,
    prefix="/banner",
    tags=["Banner"],
)