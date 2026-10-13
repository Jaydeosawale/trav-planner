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
from app.api.v1.auth.router import router as auth_router
from app.api.v1.destination.router import router as destination_router
from app.api.v1.admin.router import router as admin_router
from app.api.v1.destination_photo.router import (
    router as destination_photo_router,
)
from app.api.v1.place.router import router as place_router
from app.api.v1.admin.place.router import (router as admin_place_router,
)
from app.api.v1.user.router import router as user_router
from app.api.v1.search.router import router as search_router
from app.api.v1.trips.router import router as trips_router
from app.api.v1.itinerary.router import router as itinerary_router
from app.api.v1.ai.router import router as ai_router

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
    tags=["Banner"],

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

api_router.include_router(
    auth_router,
    prefix="/auth",
    tags=["Authentication"],
)

api_router.include_router(
    destination_router,
    prefix="/destinations",
    tags=["Destinations"],
)

api_router.include_router(
    admin_router,
    prefix="/admin",
    tags=["Admin"],
)

api_router.include_router(
    destination_photo_router,
    prefix="/destination-photos",
)

api_router.include_router(
    place_router,
    prefix="/places",
    tags=["Places"],
)

api_router.include_router(
    user_router,
    prefix="/user",
    tags=["User"],
)

api_router.include_router(
    search_router,
    prefix="/search",
    tags=["Search"],
)

api_router.include_router(
    trips_router,
    prefix="/trips",
    tags=["Trips"],
)

api_router.include_router(
    itinerary_router,
    prefix="/itinerary",
    tags=["Itinerary"],
)

api_router.include_router(
    ai_router,
    prefix="/ai",
    tags=["AI"],
)

from app.services.discovery.router import router as discovery_router
api_router.include_router(discovery_router, prefix='/discovery', tags=['Worldwide discovery'])
