"""
Search API v1 router.
"""

from fastapi import APIRouter

from app.modules.search.router import router as search_module_router


router = APIRouter()

router.include_router(
    search_module_router,
)
