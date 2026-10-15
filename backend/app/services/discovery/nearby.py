"""Nearby search using published/cached places; user's origin is never stored."""

import json, math
from pydantic import BaseModel, Field
from sqlalchemy import select, or_
from app.modules.country.model import Country
from app.modules.state.model import State
from app.modules.city.model import City
from app.modules.place.model import Place
from app.modules.place.schema import PlaceResponse
from app.services.discovery.world import (
    DiscoveryCache,
    now,
    distance,
    visible,
    discover,
    KINDS,
)


class NearbyRequest(BaseModel):
    latitude: float = Field(ge=-90, le=90, allow_inf_nan=False)
    longitude: float = Field(ge=-180, le=180, allow_inf_nan=False)
    radius_km: float = Field(default=5, ge=0.2, le=20, allow_inf_nan=False)
    kind: str = Field(default="all", max_length=20)


def bounds(model, lat, lon, radius):
    dy = radius / 110
    dx = min(180, radius / (110 * max(0.001, abs(math.cos(math.radians(lat))))))
    parts = [model.latitude.between(lat - dy, lat + dy)]
    if dx < 180:
        low, high = lon - dx, lon + dx
        if low < -180:
            parts.append(or_(model.longitude >= low + 360, model.longitude <= high))
        elif high > 180:
            parts.append(or_(model.longitude >= low, model.longitude <= high - 360))
        else:
            parts.append(model.longitude.between(low, high))
    return parts


async def search(db, payload, *, enrich=True):
    from fastapi import HTTPException

    if payload.kind != "all" and payload.kind not in KINDS:
        raise HTTPException(422, "Unsupported nearby category.")
    lat, lon = payload.latitude, payload.longitude
    cities = (
        await db.scalars(
            select(City)
            .join(State, State.id == City.state_id)
            .join(Country, Country.id == City.country_id)
            .where(
                Country.is_active.is_(True),
                Country.is_deleted.is_(False),
                State.is_active.is_(True),
                State.is_deleted.is_(False),
                City.is_active.is_(True),
                City.is_deleted.is_(False),
                *bounds(City, lat, lon, 40)
            )
            .limit(150)
        )
    ).all()
    cities = sorted(
        cities, key=lambda c: distance(lat, lon, float(c.latitude), float(c.longitude))
    )[:30]
    city_names = {c.id: c.name for c in cities}
    rows = (
        await db.scalars(
            select(DiscoveryCache)
            .where(
                DiscoveryCache.kind == "candidate",
                DiscoveryCache.city_id.in_(city_names),
                DiscoveryCache.expires_at > now(),
            )
            .limit(500)
        )
    ).all()
    matching_cached = any(
        payload.kind == "all" or json.loads(r.value).get("place_type") == payload.kind
        for r in rows
    )
    published_query = select(Place.id).where(
        Place.city_id.in_(city_names),
        Place.is_active.is_(True),
        Place.is_deleted.is_(False),
        *bounds(Place, lat, lon, payload.radius_km)
    )
    if payload.kind != "all":
        published_query = published_query.where(Place.place_type == payload.kind)
    matching_published = await db.scalar(published_query.limit(1))
    notice = ""
    if (
        enrich
        and not matching_cached
        and not matching_published
        and cities
        and (payload.kind in KINDS or payload.kind == "all")
    ):
        cached_cities = {r.city_id for r in rows}
        source_city = next((c for c in cities if c.id in cached_cities), cities[0])
        result = await discover(
            db, source_city.id, "local" if payload.kind == "all" else payload.kind
        )
        notice = result.get("message", "")
        rows = (
            await db.scalars(
                select(DiscoveryCache)
                .where(
                    DiscoveryCache.kind == "candidate",
                    DiscoveryCache.city_id.in_(city_names),
                    DiscoveryCache.expires_at > now(),
                )
                .limit(500)
            )
        ).all()
    groups = {}
    for r in rows:
        groups.setdefault(r.city_id, []).append(json.loads(r.value))
    items = {}
    for city_id, group in groups.items():
        for p in await visible(db, group, city_id):
            items[p["id"]] = p
    published = (
        await db.scalars(
            select(Place)
            .join(City, City.id == Place.city_id)
            .join(State, State.id == City.state_id)
            .join(Country, Country.id == City.country_id)
            .where(
                Country.is_active.is_(True),
                Country.is_deleted.is_(False),
                State.is_active.is_(True),
                State.is_deleted.is_(False),
                City.is_active.is_(True),
                City.is_deleted.is_(False),
                *([] if payload.kind == "all" else [Place.place_type == payload.kind]),
                Place.is_active.is_(True),
                Place.is_deleted.is_(False),
                *bounds(Place, lat, lon, payload.radius_km)
            )
            .limit(500)
        )
    ).all()
    for p in published:
        items[p.id] = PlaceResponse.model_validate(p).model_dump(mode="json")
    output = []
    for p in items.values():
        if p.get("latitude") is None or p.get("longitude") is None:
            continue
        if payload.kind != "all" and p.get("place_type") != payload.kind:
            continue
        km = distance(lat, lon, float(p["latitude"]), float(p["longitude"]))
        if km <= payload.radius_km:
            output.append(
                {
                    **p,
                    "distance_km": round(km, 2),
                    "city_name": city_names.get(p["city_id"], "Nearby"),
                }
            )
    return {
        "items": sorted(output, key=lambda p: p["distance_km"])[:20],
        "message": notice
        or (
            "Nearby listings from stored source data."
            if output
            else "No matching listings are available in this area yet. Try a larger radius, another category or explore a city."
        ),
        "distance_note": "Straight-line distances, not walking routes. Hours, prices and availability are unverified.",
    }
