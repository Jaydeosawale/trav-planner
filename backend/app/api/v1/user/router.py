"""
User travel intelligence API router.
"""

from fastapi import APIRouter

from app.modules.user.router import router as user_module_router


router = APIRouter()

router.include_router(
    user_module_router,
)