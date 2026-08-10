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
from app.modules.planner.model import Planner


__all__ = [
    "Banner",
    "Category",
    "Country",
    "State",
    "City",
    "Destination",
    "Planner"


]