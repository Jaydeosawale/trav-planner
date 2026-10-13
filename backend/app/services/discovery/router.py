from datetime import timedelta
from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database.session import get_db
from app.dependencies.current_user import get_current_user
from app.dependencies.admin import get_current_admin
from app.services.discovery.world import (
    discover,
    photo,
    resolve,
    stats,
    cache_put,
    now,
    DiscoveryCache,
)
from app.modules.place.schema import PlaceResponse

router = APIRouter()


@router.get("/cities/{city_id}")
async def city_discovery(
    city_id: str,
    kind: str = Query(default="attraction"),
    db: AsyncSession = Depends(get_db),
    user=Depends(get_current_user),
):
    return await discover(db, city_id, kind)


@router.post("/places/{ident}/resolve")
async def save_candidate(
    ident: str, db: AsyncSession = Depends(get_db), user=Depends(get_current_user)
):
    return PlaceResponse.model_validate(await resolve(db, ident))


@router.get("/places/{ident}/photo")
async def candidate_photo(
    ident: str, db: AsyncSession = Depends(get_db), user=Depends(get_current_user)
):
    return await photo(db, ident)


@router.get("/admin/status")
async def status(db: AsyncSession = Depends(get_db), admin=Depends(get_current_admin)):
    return await stats(db)


class DiscoverySettings(BaseModel):
    enabled: bool = True
    daily_calls: int = Field(default=200, ge=0, le=200)


@router.put("/admin/settings")
async def configure(
    payload: DiscoverySettings,
    db: AsyncSession = Depends(get_db),
    admin=Depends(get_current_admin),
):
    await cache_put(
        db, "settings", "settings", payload.model_dump(), timedelta(days=36500)
    )
    from app.modules.admin.model import AIBillingAuditLog
    from app.services.discovery.world import now
    import json

    db.add(
        AIBillingAuditLog(
            action="discovery_settings_update",
            new_mode="free_only",
            paid_enabled=False,
            paid_provider="none",
            daily_budget=0,
            monthly_budget=0,
            admin_id=str(admin.id),
            details=json.dumps(payload.model_dump()),
            created_at=now(),
        )
    )
    await db.commit()
    return await stats(db)


@router.get("/admin/candidates")
async def candidates(
    page: int = Query(default=1, ge=1),
    db: AsyncSession = Depends(get_db),
    admin=Depends(get_current_admin),
):
    import json

    rows = (
        await db.scalars(
            select(DiscoveryCache)
            .where(
                DiscoveryCache.kind == "candidate", DiscoveryCache.expires_at > now()
            )
            .order_by(DiscoveryCache.key)
            .offset((page - 1) * 20)
            .limit(20)
        )
    ).all()
    output = []
    from app.modules.place.model import Place

    for row in rows:
        item = json.loads(row.value)
        place = await db.get(Place, item["id"])
        item["reviewed"] = place is not None and not place.is_discovery
        output.append(item)
    return output


@router.post("/admin/candidates/{ident}/publish")
async def publish(
    ident: str, db: AsyncSession = Depends(get_db), admin=Depends(get_current_admin)
):
    place = await resolve(db, ident)
    place.content_revision = "reviewed-discovery-v1"
    await db.commit()
    return PlaceResponse.model_validate(place)


from app.services.discovery.imports import OSMPack, import_pack


@router.post("/admin/osm-pack")
async def osm_pack(
    payload: OSMPack,
    db: AsyncSession = Depends(get_db),
    admin=Depends(get_current_admin),
):
    return await import_pack(db, payload)


@router.get("/near/{ident}")
async def nearby_food(
    ident: str,
    radius_km: float = Query(default=2, ge=0.1, le=10),
    db: AsyncSession = Depends(get_db),
    user=Depends(get_current_user),
):
    import json
    from app.modules.place.model import Place
    from app.services.discovery.world import candidate, now, visible, distance

    place = await db.get(Place, ident)
    if place is not None:
        if place.is_deleted or not place.is_active:
            from fastapi import HTTPException

            raise HTTPException(404, "Place unavailable.")
        city_id = place.city_id
        lat, lon = place.latitude, place.longitude
    else:
        _, source = await candidate(db, ident)
        city_id = source["city_id"]
        lat, lon = source.get("latitude"), source.get("longitude")
    if lat is None or lon is None:
        return {"items": [], "message": "This place needs verified coordinates."}
    rows = (
        await db.scalars(
            select(DiscoveryCache)
            .where(
                DiscoveryCache.city_id == city_id,
                DiscoveryCache.kind == "candidate",
                DiscoveryCache.expires_at > now(),
            )
            .limit(200)
        )
    ).all()
    cached = await visible(db, [json.loads(r.value) for r in rows], city_id)
    published = (
        await db.scalars(
            select(Place)
            .where(
                Place.city_id == city_id,
                Place.place_type.in_(["restaurant", "cafe"]),
                Place.is_active.is_(True),
                Place.is_deleted.is_(False),
            )
            .limit(100)
        )
    ).all()
    entries = {i["id"]: i for i in cached}
    entries.update(
        {
            p.id: PlaceResponse.model_validate(p).model_dump(mode="json")
            for p in published
        }
    )
    result = []
    for item in entries.values():
        if (
            item["place_type"] not in ["restaurant", "cafe"]
            or item.get("latitude") is None
            or item.get("longitude") is None
        ):
            continue
        km = distance(
            float(lat), float(lon), float(item["latitude"]), float(item["longitude"])
        )
        if km <= radius_km:
            result.append({**item, "distance_km": round(km, 2)})
    return {
        "items": sorted(result, key=lambda i: i["distance_km"])[:20],
        "message": "Straight-line distances; current menus, opening hours and availability are unverified.",
    }
