"""
Import all SQLAlchemy models here.

Alembic imports this module so every model is registered
with Base.metadata.
"""

from app.modules.banner.model import Banner
from app.modules.category.model import Category
from app.modules.country.model import Country
from app.modules.state.model import State
from app.modules.city.model import City
from app.modules.auth.model import User
from app.modules.destination.model import Destination
from app.modules.destination_photo.model import DestinationPhoto
from app.modules.place.model import Place
from app.modules.planner.model import Planner
from app.modules.admin.model import (
    AIBillingAuditLog,
    AIBillingSettings,
)


__all__ = [
    "Banner",
    "Category",
    "Country",
    "State",
    "City",
    "User",
    "Destination",
    "DestinationPhoto",
    "Place",
    "Planner",
    "AIBillingSettings",
    "AIBillingAuditLog",
]
from app.services.ai.routing import AIRoutingSettings

from app.services.ai.conversations import PlannerConversation

from app.services.discovery.models import DiscoveryCache, DiscoveryBudget

from app.services.ai.itinerary_models import ItineraryDraft
