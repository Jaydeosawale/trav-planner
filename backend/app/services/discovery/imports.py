"""Admin-reviewed OSM packs; no public Overpass dependency."""

from datetime import timedelta
from fastapi import HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select
from app.modules.city.model import City
from app.services.discovery.world import cache_put, uid, distance, stats, MAX_DB_BYTES

TYPES = {
    "attraction",
    "museum",
    "park",
    "beach",
    "heritage",
    "restaurant",
    "cafe",
    "hotel",
    "station",
    "bus_stop",
    "airport",
    "parking",
    "shop",
    "pharmacy",
    "hospital",
    "worship",
    "toilet",
    "viewpoint",
    "charging",
}


class OSMItem(BaseModel):
    external_id: str = Field(pattern=r"^(node|way|relation)/[1-9][0-9]*$")
    name: str = Field(min_length=2, max_length=200)
    place_type: str = Field(max_length=30)
    latitude: float = Field(ge=-90, le=90, allow_inf_nan=False)
    longitude: float = Field(ge=-180, le=180, allow_inf_nan=False)
    description: str = Field(default="", max_length=1000)


class OSMPack(BaseModel):
    city_id: str = Field(max_length=36)
    license: str = Field(pattern=r"^ODbL-1\.0$")
    items: list[OSMItem] = Field(max_length=200, min_length=1)


async def import_pack(db, pack):
    city = await db.scalar(
        select(City).where(
            City.id == pack.city_id,
            City.is_active.is_(True),
            City.is_deleted.is_(False),
        )
    )
    if city is None or city.latitude is None or city.longitude is None:
        raise HTTPException(422, "Choose an active city with coordinates.")
    if any(
        p.place_type not in TYPES
        or distance(
            float(city.latitude), float(city.longitude), p.latitude, p.longitude
        )
        > 40
        for p in pack.items
    ):
        raise HTTPException(
            422, "Unsupported type or place outside this destination area."
        )
    usage = await stats(db)
    if usage["database_bytes"] is not None and usage["database_bytes"] >= MAX_DB_BYTES:
        raise HTTPException(409, "Free storage limit reached.")
    for p in pack.items:
        record = {
            "id": uid("osm:" + p.external_id),
            "city_id": city.id,
            "slug": "osm-" + p.external_id.replace("/", "-"),
            "name": p.name,
            "place_type": p.place_type,
            "latitude": p.latitude,
            "longitude": p.longitude,
            "description": p.description,
            "provider": "osm",
            "external_place_id": p.external_id,
            "is_active": True,
            "is_featured": False,
            "is_discovery": True,
            "image_url": None,
            "image_credit": None,
            "visiting_notes": "OpenStreetMap source data. Current business hours, prices and availability are not verified.",
        }
        await cache_put(db, record["id"], "candidate", record, timedelta(days=30))
    await db.commit()
    return {
        "imported": len(pack.items),
        "review_required": True,
        "source": "OpenStreetMap contributors",
        "license": "ODbL-1.0",
    }
