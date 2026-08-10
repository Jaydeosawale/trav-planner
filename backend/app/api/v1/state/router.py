"""
State API v1 Router.
"""

from fastapi import APIRouter

from app.modules.state.router import router as state_router


router = APIRouter()

router.include_router(
    state_router,
     tags=["States"],
)