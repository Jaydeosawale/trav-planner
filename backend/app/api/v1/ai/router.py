"""
Normal-user AI API.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends

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
) -> AIChatResponse:
    """
    Handle a normal user's AI request.

    The request is passed to the TravelPlanningAgent,
    which is responsible for the AI Gateway, provider
    selection, tool calling and continuation.
    """

    agent = TravelPlanningAgent()

    context = AgentContext(
        user_id=str(current_user.id),
        session_id=request.session_id,
    )

    result = await agent.run(
        request.message,
        context=context,
    )

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
