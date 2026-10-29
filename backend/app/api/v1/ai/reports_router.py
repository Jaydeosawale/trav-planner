"""Authenticated, owned-content reports; review is restricted to administrators."""
import json
from datetime import datetime, timedelta, timezone
from typing import Literal
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.database.session import get_db
from app.dependencies.current_user import get_current_user
from app.dependencies.admin import get_current_admin
from app.modules.auth.model import User
from app.services.ai.content_reports import AIContentReport
from app.services.ai.conversations import PlannerConversation
from app.services.ai.itinerary_models import ItineraryDraft

router = APIRouter()

class ReportRequest(BaseModel):
    source_kind: Literal['chat', 'itinerary']
    reference_id: str = Field(min_length=1, max_length=36)
    reason: Literal['unsafe', 'hate_or_harassment', 'sexual_content', 'misleading', 'other']
    details: str = Field(default='', max_length=1000)

class ReviewRequest(BaseModel):
    status: Literal['reviewed', 'actioned', 'dismissed']

@router.post('/content-reports', status_code=201)
async def submit_report(request: ReportRequest, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    model = PlannerConversation if request.source_kind == 'chat' else ItineraryDraft
    source = await db.scalar(select(model).where(model.id == request.reference_id, model.user_id == str(user.id)))
    if source is None:
        raise HTTPException(404, 'AI content not found.')
    since = datetime.now(timezone.utc) - timedelta(days=1)
    count = await db.scalar(select(func.count()).select_from(AIContentReport).where(AIContentReport.user_id == str(user.id), AIContentReport.created_at >= since))
    if count >= 20:
        raise HTTPException(429, 'Daily report limit reached. Please try again tomorrow.')
    if request.source_kind == 'chat':
        # Preserve only the latest generated answer, never the user's entire chat.
        answers = [t.get('content', '') for t in json.loads(source.turns_json) if t.get('role') == 'assistant']
        content = answers[-1] if answers else ''
    else:
        content = source.content_json
    if not content:
        raise HTTPException(422, 'There is no generated content to report.')
    row = AIContentReport(user_id=str(user.id), source_kind=request.source_kind, reference_id=request.reference_id, reason=request.reason, details=request.details.strip(), content_excerpt=content[:16000], status='pending')
    db.add(row)
    await db.commit()
    await db.refresh(row)
    return {'id': row.id, 'status': row.status}

@router.get('/content-reports')
async def list_reports(user: User = Depends(get_current_admin), db: AsyncSession = Depends(get_db)):
    rows = (await db.scalars(select(AIContentReport).order_by(AIContentReport.created_at.desc()).limit(100))).all()
    return [{'id': r.id, 'source_kind': r.source_kind, 'reason': r.reason, 'details': r.details, 'content_excerpt': r.content_excerpt, 'status': r.status, 'created_at': r.created_at} for r in rows]

@router.patch('/content-reports/{report_id}')
async def review_report(report_id: str, request: ReviewRequest, user: User = Depends(get_current_admin), db: AsyncSession = Depends(get_db)):
    row = await db.get(AIContentReport, report_id)
    if row is None:
        raise HTTPException(404, 'Report not found.')
    row.status = request.status
    await db.commit()
    return {'id': row.id, 'status': row.status}
