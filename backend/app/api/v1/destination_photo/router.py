from fastapi import APIRouter

from app.modules.destination_photo.router import (
    router as destination_photo_module_router,
)

router = APIRouter()

router.include_router(
    destination_photo_module_router,
)