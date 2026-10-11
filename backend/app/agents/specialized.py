from __future__ import annotations

from typing import Any

from app.agents.base import Agent, AgentContext, AgentResponse
from app.database.session import SessionLocal
from app.services.ai.contracts import RetrievalPlan
from app.services.ai.discovery import (
    DestinationDiscoveryService,
    DiscoveryRankingContext,
)
from app.services.ai.orchestrator import TravelAIOrchestrator


class DiscoveryAgent(Agent):
    """
    Finds destinations and places from internal data plus configured
    discovery providers.
    """

    def __init__(
        self,
        *,
        discovery_service: DestinationDiscoveryService | None = None,
    ) -> None:
        self.discovery_service = (
            discovery_service or DestinationDiscoveryService()
        )
        self.orchestrator = TravelAIOrchestrator()

    @property
    def name(self) -> str:
        return "discovery"

    @property
    def description(self) -> str:
        return "Discover and rank destinations, places and POIs."

    async def run(
        self,
        request: str,
        *,
        context: AgentContext | None = None,
        **kwargs: Any,
    ) -> AgentResponse:
        orchestration = await self.orchestrator.plan(request)
        query = orchestration.query

        ranking_context = DiscoveryRankingContext(
            query=query.normalized,
            preferred_interests=query.entities.interests,
            preferred_categories=(
                (query.entities.place_type,)
                if query.entities.place_type
                else ()
            ),
        )

        plan = orchestration.retrieval

        if not (
            plan.use_postgres
            or plan.use_google_places
            or plan.use_osm
            or plan.use_bm25
            or plan.use_vector
        ):
            plan = RetrievalPlan(
                use_postgres=True,
                use_bm25=True,
                use_vector=True,
                use_reranker=True,
            )

        async with SessionLocal() as db:
            result = await self.discovery_service.discover(
                db,
                query=query.normalized,
                plan=plan,
                ranking_context=ranking_context,
                entity_type=query.entities.place_type,
                limit=kwargs.get("limit", 10),
            )

        items = [
            _ranked_item(item)
            for item in result.ranked
        ]

        return AgentResponse(
            content=(
                "I found matching options."
                if items
                else "I could not find matching options yet."
            ),
            agent=self.name,
            success=True,
            data={
                "items": items,
                "sources_used": result.sources_used,
            },
            metadata={
                **result.metadata,
                "intent": query.intent.value,
                "response_type": (
                    orchestration.agent_plan.response_type.value
                ),
            },
        )


class HospitalityAgent(DiscoveryAgent):
    """
    Hotel and restaurant discovery agent.
    """

    @property
    def name(self) -> str:
        return "hospitality"

    @property
    def description(self) -> str:
        return "Find hotels, stays, restaurants and cafes."


class TransportAgent(DiscoveryAgent):
    """
    Airport, railway, flight, train and route discovery agent.
    """

    @property
    def name(self) -> str:
        return "transport"

    @property
    def description(self) -> str:
        return "Resolve airports, railway stations and travel routes."


class CurrentKnowledgeAgent(Agent):
    """
    Policy/current-knowledge boundary.

    Fresh policy, visa, schedule and weather answers should use
    authoritative or live tools before final LLM wording.
    """

    @property
    def name(self) -> str:
        return "current_knowledge"

    @property
    def description(self) -> str:
        return "Answer current policy, visa, advisory and weather needs."

    async def run(
        self,
        request: str,
        *,
        context: AgentContext | None = None,
        **kwargs: Any,
    ) -> AgentResponse:
        return AgentResponse(
            content=(
                "This request needs fresh authoritative information. "
                "I should use an official-source, weather or schedule "
                "connector before giving a final answer."
            ),
            agent=self.name,
            success=True,
            data={
                "request": request,
                "requires_fresh_source": True,
            },
            metadata={
                "intent_boundary": "current_information",
                "may_use_llm_after_evidence": True,
            },
        )


class BookingActionAgent(Agent):
    """
    Booking/action guardrail agent.

    It never books, pays, cancels or modifies anything unless the
    caller provides explicit user confirmation and exact action data.
    """

    @property
    def name(self) -> str:
        return "booking_action"

    @property
    def description(self) -> str:
        return "Prepare booking actions and enforce confirmation."

    async def run(
        self,
        request: str,
        *,
        context: AgentContext | None = None,
        **kwargs: Any,
    ) -> AgentResponse:
        confirmed = bool(kwargs.get("confirmed"))

        if not confirmed:
            return AgentResponse(
                content=(
                    "I can help prepare that, but I need explicit "
                    "confirmation before any booking, cancellation, "
                    "payment or change is made."
                ),
                agent=self.name,
                success=False,
                data={
                    "confirmation_required": True,
                    "request": request,
                },
                metadata={
                    "action_status": "blocked_pending_confirmation",
                },
            )

        return AgentResponse(
            content=(
                "Confirmation received. A concrete booking provider "
                "adapter must execute the action and return its "
                "official confirmation result."
            ),
            agent=self.name,
            success=True,
            data={
                "confirmation_required": False,
                "request": request,
            },
            metadata={
                "action_status": "ready_for_provider_execution",
            },
        )


def _ranked_item(item) -> dict[str, Any]:
    entity = item.entity

    return {
        "id": entity.canonical_id,
        "name": entity.canonical_name,
        "entity_type": entity.entity_type,
        "country": entity.country,
        "state": entity.state,
        "city": entity.city,
        "latitude": entity.latitude,
        "longitude": entity.longitude,
        "description": entity.description,
        "category": entity.category,
        "tags": entity.tags,
        "sources": entity.sources,
        "score": item.final_score,
        "reasons": item.reasons,
    }


__all__ = [
    "DiscoveryAgent",
    "HospitalityAgent",
    "TransportAgent",
    "CurrentKnowledgeAgent",
    "BookingActionAgent",
]
