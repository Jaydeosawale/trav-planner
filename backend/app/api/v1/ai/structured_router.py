import json
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from app.database.session import get_db
from app.dependencies.current_user import get_current_user
from app.services.ai import structured_itinerary as plans
from app.services.ai.itinerary_models import ItineraryDraft
from app.services.discovery.world import now, future

router = APIRouter()


@router.post("/itinerary-drafts")
async def generate(
    request: plans.GeneratePlan, db=Depends(get_db), user=Depends(get_current_user)
):
    return await plans.generate(db, str(user.id), request)


@router.get("/itinerary-drafts")
async def recent(db=Depends(get_db), user=Depends(get_current_user)):
    rows = (
        await db.scalars(
            select(ItineraryDraft)
            .where(
                ItineraryDraft.user_id == str(user.id),
                ItineraryDraft.trip_id.is_(None),
                ItineraryDraft.expires_at > now(),
            )
            .order_by(ItineraryDraft.created_at.desc())
            .limit(20)
        )
    ).all()
    return [
        {"id": r.id, "title": json.loads(r.content_json)["plan"]["title"]} for r in rows
    ]


@router.get("/itinerary-drafts/{ident}")
async def preview(ident: str, db=Depends(get_db), user=Depends(get_current_user)):
    row = await db.scalar(
        select(ItineraryDraft).where(
            ItineraryDraft.id == ident, ItineraryDraft.user_id == str(user.id)
        )
    )
    if row is None or (row.trip_id is None and future(row.expires_at) < now()):
        raise HTTPException(404, "Draft unavailable.")
    return {
        "id": row.id,
        **json.loads(row.content_json),
        "trip_id": row.trip_id,
        "expires_at": row.expires_at,
        "estimated": True,
    }


@router.post("/itinerary-drafts/{ident}/save")
async def save(
    ident: str,
    request: plans.SavePlan,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    return await plans.save(db, str(user.id), ident, request)


@router.delete("/itinerary-drafts/{ident}")
async def discard(ident: str, db=Depends(get_db), user=Depends(get_current_user)):
    row = await db.scalar(
        select(ItineraryDraft).where(
            ItineraryDraft.id == ident, ItineraryDraft.user_id == str(user.id)
        )
    )
    if row is None:
        raise HTTPException(404, "Draft unavailable.")
    if row.trip_id:
        raise HTTPException(409, "This draft is saved. Manage its trip in My Trips.")
    await db.delete(row)
    await db.commit()
    return {"discarded": True}
