"""
Planner API endpoints.
"""

from fastapi import APIRouter

router = APIRouter()


@router.get(
    "/",
    summary="Planner API",
)
async def planner_home():
    """
    Planner health endpoint.
    """

    return {
        "module": "planner",
        "status": "ready",
        "message": "Planner module is running",
    }