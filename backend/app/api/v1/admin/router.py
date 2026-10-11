from fastapi import APIRouter
from fastapi import Depends

from app.dependencies.admin import get_current_admin
from app.modules.auth.model import User
from app.api.v1.admin.ai_billing.router import (
    router as admin_ai_billing_router,
)
from app.modules.admin.router import (
    router as admin_dashboard_router,
)

from app.api.v1.admin.banner.router import (
    router as admin_banner_router,
)

from app.api.v1.admin.place.router import (
    router as admin_place_router,
)
from app.api.v1.admin.country.router import (
    router as admin_country_router,
)

router = APIRouter()


@router.get("/me")
async def get_admin_me(
    current_admin: User = Depends(get_current_admin),
):
    return {
        "success": True,
        "data": {
            "id": str(current_admin.id),
            "email": current_admin.email,
            "full_name": current_admin.full_name,
            "role": current_admin.role,
        },
    }


# ==========================================================
# Admin Dashboard
# ==========================================================

router.include_router(
    admin_dashboard_router,
)


# ==========================================================
# Admin Banner Management
# ==========================================================

router.include_router(
    admin_banner_router,
    prefix="/banners",
    tags=["Admin - Banners"],
)


# ==========================================================
# Admin Place Management
# ==========================================================

router.include_router(
    admin_place_router,
    prefix="/places",
    tags=["Admin - Places"],
)

# ==========================================================
# Admin Country Management
# ==========================================================

router.include_router(
    admin_country_router,
    prefix="/countries",
    tags=["Admin - Countries"],
)

# ==========================================================
# AI Billing Management
# ==========================================================

router.include_router(
    admin_ai_billing_router,
    prefix="/ai-billing",
    tags=["Admin - AI Billing"],
)