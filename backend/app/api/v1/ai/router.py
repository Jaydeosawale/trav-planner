"""
Normal-user AI API.
"""

from __future__ import annotations

import json

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.database.session import get_db
from app.services.ai.conversations import PlannerConversation, owned, payload, replace, context_prompt
from .schema import ConversationDraft

from app.agents.base import AgentContext
from app.agents.travel_planner import TravelPlanningAgent
from app.dependencies.current_user import get_current_user
from app.modules.auth.model import User

from .schema import (
    AIChatData,
    AIChatRequest,
    AIChatResponse,
)


router = APIRouter()


@router.post(
    "/chat",
    response_model=AIChatResponse,
    summary="Ask Trav Planner AI",
)
async def chat_with_ai(
    request: AIChatRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> AIChatResponse:
    """
    Handle a normal user's AI request.

    The request is passed to the TravelPlanningAgent,
    which is responsible for the AI Gateway, provider
    selection, tool calling and continuation.
    """

    row = None
    if request.session_id:
        row = await owned(db, request.session_id, str(current_user.id))
    if row is None:
        count = await db.scalar(select(func.count()).select_from(PlannerConversation).where(PlannerConversation.user_id == str(current_user.id)))
        if count >= 20:
            raise HTTPException(409, 'You have 20 saved conversations. Reopen a recent plan or forget an old conversation to start another.')
    agent = TravelPlanningAgent()

    context = AgentContext(
        user_id=str(current_user.id),
        session_id=request.session_id,
        data={'planner_prompt': context_prompt(request.message, json.loads(row.brief_json), json.loads(row.turns_json))} if row else {},
    )

    result = await agent.run(
        request.message,
        context=context,
    )

    if row is None and result.success:
        row = PlannerConversation(user_id=str(current_user.id), title=request.message[:100] or 'Travel ideas', brief_json='{}', turns_json='[]', version=0)
        db.add(row)
        await db.flush()
    if row is not None and result.success:
        turns = json.loads(row.turns_json) + [
            {'role': 'user', 'content': request.message[:10000]},
            {'role': 'assistant', 'content': result.content[:16000]},
        ]
        await replace(db, row, turns=turns)
    if row is not None:
        result.metadata['session_id'] = row.id
    return AIChatResponse(
        success=result.success,
        data=AIChatData(
            content=result.content,
            agent=result.agent,
            success=result.success,
            data=result.data,
            metadata=result.metadata,
        ),
        message=(
            None
            if result.success
            else result.metadata.get("reason")
            or "Unable to process the AI request."
        ),
    )


@router.get('/sessions')
async def list_sessions(current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    rows = (await db.scalars(select(PlannerConversation).where(PlannerConversation.user_id == str(current_user.id)).order_by(PlannerConversation.updated_at.desc()).limit(20))).all()
    return [{'id': row.id, 'title': row.title, 'version': row.version} for row in rows]


@router.post('/sessions')
async def create_session(draft: ConversationDraft, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    row = PlannerConversation(user_id=str(current_user.id), title=draft.title, brief_json=json.dumps(draft.brief.model_dump()), turns_json='[]', version=0)
    db.add(row)
    await db.commit()
    await db.refresh(row)
    return payload(row)


@router.get('/sessions/{session_id}')
async def get_session(session_id: str, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    return payload(await owned(db, session_id, str(current_user.id)))


@router.put('/sessions/{session_id}')
async def update_session(session_id: str, draft: ConversationDraft, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    row = await owned(db, session_id, str(current_user.id))
    if draft.version is None or draft.version != row.version:
        raise HTTPException(409, 'This conversation changed. Reopen it before editing.')
    return payload(await replace(db, row, brief=draft.brief.model_dump(), title=draft.title))


@router.delete('/sessions/{session_id}')
async def forget_session(session_id: str, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    row = await owned(db, session_id, str(current_user.id))
    await db.delete(row)
    await db.commit()
    return {'forgotten': True}

from .structured_router import router as structured_router
router.include_router(structured_router)

from .reports_router import router as reports_router
router.include_router(reports_router)
