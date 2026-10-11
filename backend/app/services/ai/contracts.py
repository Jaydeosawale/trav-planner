from __future__ import annotations

from dataclasses import dataclass, field
from enum import StrEnum
from typing import Any


# ==========================================================
# USER INTENT
# ==========================================================

class Intent(StrEnum):
    """
    High-level intent detected from a user's AI request.
    """

    GENERAL_CHAT = "general_chat"

    DESTINATION_DISCOVERY = "destination_discovery"
    PLACE_SEARCH = "place_search"
    RESTAURANT_SEARCH = "restaurant_search"
    HOTEL_SEARCH = "hotel_search"
    AIRPORT_SEARCH = "airport_search"
    RAILWAY_SEARCH = "railway_search"
    FLIGHT_SEARCH = "flight_search"
    TRAIN_SEARCH = "train_search"

    TRIP_PLANNING = "trip_planning"
    ITINERARY_GENERATION = "itinerary_generation"
    TRIP_MODIFICATION = "trip_modification"

    ROUTE_PLANNING = "route_planning"
    WEATHER = "weather"

    VISA_POLICY = "visa_policy"
    TRAVEL_POLICY = "travel_policy"
    CURRENT_INFORMATION = "current_information"

    BOOKING_ACTION = "booking_action"


# ==========================================================
# RESPONSE TYPE
# ==========================================================

class ResponseType(StrEnum):
    """
    Tells Flutter how the final AI response should be rendered.
    """

    ANSWER = "answer"

    CLARIFICATION = "clarification"

    RECOMMENDATIONS = "recommendations"

    TRIP_PLAN = "trip_plan"

    POLICY_ANSWER = "policy_answer"

    ERROR = "error"


# ==========================================================
# DATA SENSITIVITY
# ==========================================================

class DataSensitivity(StrEnum):
    """
    Classification used by the context/privacy layer.

    Not every internal field is allowed to cross the
    LLM/provider boundary.
    """

    PUBLIC = "public"

    USER_DERIVED = "user_derived"

    USER_PRIVATE = "user_private"

    RESTRICTED = "restricted"


# ==========================================================
# QUERY ENTITIES
# ==========================================================

@dataclass(slots=True)
class QueryEntities:
    """
    Structured information extracted from a user's query.

    These are normalized task entities, not a raw copy of
    the user's profile/database record.
    """

    destination: str | None = None

    origin: str | None = None

    city: str | None = None

    country: str | None = None

    duration_days: int | None = None

    traveler_count: int | None = None

    budget_amount: float | None = None

    budget_currency: str | None = None

    travel_dates: tuple[str, str] | None = None

    interests: tuple[str, ...] = ()

    nationality: str | None = None

    place_type: str | None = None

    raw: dict[str, Any] = field(
        default_factory=dict,
    )


# ==========================================================
# QUERY STATE
# ==========================================================

@dataclass(slots=True)
class QueryState:
    """
    Complete normalized understanding of the current user query.
    """

    original: str

    normalized: str

    language: str = "en"

    intent: Intent = Intent.GENERAL_CHAT

    confidence: float = 0.0

    entities: QueryEntities = field(
        default_factory=QueryEntities,
    )

    missing_slots: tuple[str, ...] = ()

    requires_clarification: bool = False


# ==========================================================
# RETRIEVAL PLAN
# ==========================================================

@dataclass(slots=True)
class RetrievalPlan:
    """
    Describes which knowledge/data sources are appropriate
    for the current request.

    The orchestrator decides this.
    """

    # Structured internal application data.
    use_postgres: bool = False

    # Semantic retrieval.
    use_vector: bool = False

    # Lexical retrieval.
    use_bm25: bool = False

    # Second-stage relevance ranking.
    use_reranker: bool = False

    # Live location/place sources.
    use_google_places: bool = False

    use_osm: bool = False

    # Live routing.
    use_maps: bool = False

    # Live weather.
    use_weather: bool = False

    # Authoritative current sources.
    use_official_sources: bool = False

    # Whether stale/cached information is unacceptable.
    must_be_fresh: bool = False

    # Queries after normalization/refinement.
    retrieval_queries: tuple[str, ...] = ()


# ==========================================================
# AGENT PLAN
# ==========================================================

@dataclass(slots=True)
class AgentPlan:
    """
    Execution plan produced by the orchestrator.
    """

    agents: tuple[str, ...] = ()

    tools: tuple[str, ...] = ()

    response_type: ResponseType = ResponseType.ANSWER

    clarification_question: str | None = None

    rationale: str | None = None


# ==========================================================
# EVIDENCE
# ==========================================================

@dataclass(slots=True)
class EvidenceRef:
    """
    Source/evidence reference retained during AI execution.

    The LLM can receive the useful content, while the application
    keeps source metadata for verification and UI citation.
    """

    evidence_id: str

    title: str

    source_type: str

    source_url: str | None = None

    retrieved_at: str | None = None

    verified_at: str | None = None

    trust_level: str = "unknown"

    relevance_score: float | None = None


# ==========================================================
# ORCHESTRATION RESULT
# ==========================================================

@dataclass(slots=True)
class OrchestrationResult:
    """
    Complete decision produced before agent execution.
    """

    query: QueryState

    retrieval: RetrievalPlan

    agent_plan: AgentPlan

    # This is already sanitized for provider use.
    context_packet: dict[str, Any]

    evidence: tuple[EvidenceRef, ...] = ()
