"""
Planner API endpoints.
"""

from fastapi import APIRouter
from app.modules.destination.router import router as planner_router

router = APIRouter()

router.include_router(
   planner_router,
    tags=["Planner"],
)