"""
Admin module router.
"""

from __future__ import annotations

from fastapi import APIRouter
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db
from app.dependencies.admin import get_current_admin
from app.modules.admin.service import AdminService
from app.modules.auth.model import User


router = APIRouter()


@router.get(
    "/dashboard",
    summary="Get Admin Dashboard",
)
async def get_admin_dashboard(
    current_admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Return aggregated statistics for the Admin Dashboard.
    """

    dashboard = await AdminService.get_dashboard(db)

    return {
        "success": True,
        "data": dashboard,
    }
