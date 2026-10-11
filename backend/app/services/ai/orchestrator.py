from __future__ import annotations

from app.services.ai.context import (
    ContextFirewall,
    UserContextSnapshot,
)
from app.services.ai.contracts import (
    AgentPlan,
    Intent,
    OrchestrationResult,
    ResponseType,
    RetrievalPlan,
)
from app.services.ai.query import (
    QueryUnderstanding,
    RequirementPolicy,
)


class TravelAIOrchestrator:
    """
    Deterministic AI navigation router.

    This layer decides which data sources and specialist agents are
    appropriate before any LLM/provider call is made.
    """

    async def plan(
        self,
        message: str,
        *,
        context: UserContextSnapshot | None = None,
    ) -> OrchestrationResult:
        recent_turns = (
            context.recent_turns
            if context is not None
            else ()
        )

        query = QueryUnderstanding.analyze(
            message,
            recent_turns=recent_turns,
        )

        retrieval = self._retrieval_plan(query.intent)
        retrieval.retrieval_queries = (
            (query.normalized,)
            if query.normalized
            else ()
        )

        agent_plan = self._agent_plan(query.intent)

        if query.requires_clarification:
            agent_plan = AgentPlan(
                agents=agent_plan.agents,
                tools=agent_plan.tools,
                response_type=ResponseType.CLARIFICATION,
                clarification_question=(
                    RequirementPolicy.minimum_question(query)
                ),
                rationale=agent_plan.rationale,
            )

        context_packet: dict = {}

        if context is not None:
            packet = ContextFirewall.build_packet(
                context,
                destination=query.entities.destination,
                traveler_count=query.entities.traveler_count,
                duration_days=query.entities.duration_days,
            )
            context_packet = ContextFirewall.to_payload(packet)

        return OrchestrationResult(
            query=query,
            retrieval=retrieval,
            agent_plan=agent_plan,
            context_packet=context_packet,
            evidence=(),
        )

    @staticmethod
    def _retrieval_plan(
        intent: Intent,
    ) -> RetrievalPlan:
        if intent in {
            Intent.DESTINATION_DISCOVERY,
            Intent.PLACE_SEARCH,
            Intent.HOTEL_SEARCH,
            Intent.RESTAURANT_SEARCH,
            Intent.AIRPORT_SEARCH,
            Intent.RAILWAY_SEARCH,
        }:
            return RetrievalPlan(
                use_postgres=True,
                use_vector=True,
                use_bm25=True,
                use_reranker=True,
                use_google_places=True,
                use_osm=True,
                must_be_fresh=(
                    intent
                    in {
                        Intent.HOTEL_SEARCH,
                        Intent.RESTAURANT_SEARCH,
                        Intent.AIRPORT_SEARCH,
                        Intent.RAILWAY_SEARCH,
                    }
                ),
            )

        if intent in {
            Intent.VISA_POLICY,
            Intent.TRAVEL_POLICY,
            Intent.CURRENT_INFORMATION,
        }:
            return RetrievalPlan(
                use_vector=True,
                use_bm25=True,
                use_reranker=True,
                use_official_sources=True,
                must_be_fresh=True,
            )

        if intent == Intent.WEATHER:
            return RetrievalPlan(
                use_weather=True,
                must_be_fresh=True,
            )

        if intent == Intent.ROUTE_PLANNING:
            return RetrievalPlan(
                use_postgres=True,
                use_google_places=True,
                use_osm=True,
                use_maps=True,
                must_be_fresh=True,
            )

        if intent in {
            Intent.FLIGHT_SEARCH,
            Intent.TRAIN_SEARCH,
        }:
            return RetrievalPlan(
                use_postgres=True,
                use_bm25=True,
                use_vector=True,
                use_official_sources=True,
                must_be_fresh=True,
            )

        if intent == Intent.BOOKING_ACTION:
            return RetrievalPlan(
                use_postgres=True,
                use_official_sources=True,
                must_be_fresh=True,
            )

        return RetrievalPlan(
            use_vector=True,
            use_bm25=True,
            use_reranker=True,
        )

    @staticmethod
    def _agent_plan(
        intent: Intent,
    ) -> AgentPlan:
        if intent in {
            Intent.DESTINATION_DISCOVERY,
            Intent.PLACE_SEARCH,
        }:
            return AgentPlan(
                agents=("discovery",),
                tools=("place_search",),
                response_type=ResponseType.RECOMMENDATIONS,
                rationale="Discover destinations and places.",
            )

        if intent in {
            Intent.HOTEL_SEARCH,
            Intent.RESTAURANT_SEARCH,
        }:
            return AgentPlan(
                agents=("hospitality",),
                tools=("place_search",),
                response_type=ResponseType.RECOMMENDATIONS,
                rationale="Find stay and food options.",
            )

        if intent in {
            Intent.AIRPORT_SEARCH,
            Intent.RAILWAY_SEARCH,
            Intent.FLIGHT_SEARCH,
            Intent.TRAIN_SEARCH,
            Intent.ROUTE_PLANNING,
        }:
            return AgentPlan(
                agents=("transport",),
                tools=("place_search", "map_routing"),
                response_type=ResponseType.ANSWER,
                rationale="Resolve transport options and routes.",
            )

        if intent in {
            Intent.VISA_POLICY,
            Intent.TRAVEL_POLICY,
            Intent.CURRENT_INFORMATION,
            Intent.WEATHER,
        }:
            return AgentPlan(
                agents=("current_knowledge",),
                tools=(),
                response_type=ResponseType.POLICY_ANSWER,
                rationale="Use fresh or authoritative information.",
            )

        if intent == Intent.BOOKING_ACTION:
            return AgentPlan(
                agents=("booking_action",),
                tools=(),
                response_type=ResponseType.CLARIFICATION,
                clarification_question=(
                    "Before I take any booking or payment action, "
                    "please confirm the exact option and total price."
                ),
                rationale="Booking actions require explicit confirmation.",
            )

        if intent in {
            Intent.TRIP_PLANNING,
            Intent.ITINERARY_GENERATION,
            Intent.TRIP_MODIFICATION,
        }:
            return AgentPlan(
                agents=("travel_planning",),
                tools=("place_search", "map_routing"),
                response_type=ResponseType.TRIP_PLAN,
                rationale="Plan or revise a trip.",
            )

        return AgentPlan(
            agents=("travel_planning",),
            response_type=ResponseType.ANSWER,
            rationale="General travel assistance.",
        )


__all__ = [
    "TravelAIOrchestrator",
]
