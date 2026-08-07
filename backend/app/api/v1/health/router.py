"""
Health endpoints.
"""

from fastapi import APIRouter

from app.common.responses.api_response import success_response

router = APIRouter()


@router.get("/", summary="Health Check")
async def health():
    return success_response(
        data={
            "status": "healthy",
            "service": "Trav Planner API",
        },
        message="Health check successful",
    )

    