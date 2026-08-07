"""
Main API Router
"""

from fastapi import APIRouter

from app.api.v1.health.router import router as health_router
from app.api.v1.planner.router import router as planner_router
from app.api.v1.banner.router import router as banner_router
from app.api.v1.category.router import router as category_router
from app.api.v1.country.router import router as country_router
from app.api.v1.state.router import router as state_router
from app.api.v1.city.router import router as city_router

api_router = APIRouter()

api_router.include_router(
    health_router,
    prefix="/health",
    tags=["Health"],
)

api_router.include_router(
    planner_router,
    prefix="/planner",
    tags=["Planner"],
)

api_router.include_router(
     banner_router,
    prefix="/banner",
    tags=["banner"],

)

api_router.include_router(
    category_router,
    prefix="/categories",
    tags=["Categories"],
)

api_router.include_router(
    country_router,
    prefix="/countries",
    tags=["Countries"],
)

api_router.include_router(
    state_router,
    prefix="/states",
    tags=["States"],
)

api_router.include_router(
    city_router,
    prefix="/cities",
    tags=["Cities"],
)