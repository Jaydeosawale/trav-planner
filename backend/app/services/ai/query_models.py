from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class QueryConfidence(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class ConstraintType(str, Enum):
    HARD = "hard"
    SOFT = "soft"
    EXCLUSION = "exclusion"


class EntityType(str, Enum):
    COUNTRY = "country"
    STATE = "state"
    CITY = "city"
    DESTINATION = "destination"
    PLACE = "place"
    HOTEL = "hotel"
    RESTAURANT = "restaurant"
    CAFE = "cafe"
    AIRPORT = "airport"
    RAILWAY_STATION = "railway_station"
    BEACH = "beach"
    ATTRACTION = "attraction"
    ACTIVITY = "activity"
    UNKNOWN = "unknown"


class ActionLevel(str, Enum):
    READ = "read"
    PREPARE = "prepare"
    CONSEQUENTIAL = "consequential"


@dataclass(slots=True)
class QueryEntity:
    """
    Entity extracted from the user's query.

    Example:
        "Goa" -> destination
        "Pune" -> city/origin
        "Baga Beach" -> beach/place
    """

    text: str
    entity_type: EntityType = EntityType.UNKNOWN

    canonical_name: str | None = None
    canonical_id: str | None = None

    confidence: float = 0.0

    # Optional geographic hierarchy.
    country: str | None = None
    state: str | None = None
    city: str | None = None


@dataclass(slots=True)
class TravelDateRange:
    """
    Resolved or partially resolved travel dates.
    """

    start_date: str | None = None
    end_date: str | None = None

    # Preserve the user's original relative expression.
    original_expression: str | None = None

    is_resolved: bool = False


@dataclass(slots=True)
class TravelConstraint:
    """
    A requirement or preference extracted from the query.
    """

    name: str
    value: Any

    constraint_type: ConstraintType = ConstraintType.SOFT

    confidence: float = 0.0

    source: str = "query"


@dataclass(slots=True)
class QueryAmbiguity:
    """
    Something the system cannot safely resolve.
    """

    field: str
    value: str

    candidates: tuple[str, ...] = ()

    confidence: float = 0.0

    clarification_required: bool = True


@dataclass(slots=True)
class QueryTask:
    """
    A decomposed task that may later be assigned to an agent/tool.

    Example:
        "Find cheap hotels and beaches in Goa"

        task 1 -> hotel discovery
        task 2 -> beach discovery
    """

    task_id: str
    task_type: str

    description: str

    dependencies: tuple[str, ...] = ()

    required_agent: str | None = None

    required_tools: tuple[str, ...] = ()


@dataclass(slots=True)
class RetrievalPlan:
    """
    Structured retrieval requirements generated from TravelQuery.
    """

    queries: tuple[str, ...] = ()

    use_postgres: bool = False
    use_bm25: bool = False
    use_vector: bool = False
    use_reranker: bool = False

    use_postgis: bool = False

    use_osm: bool = False
    use_geonames: bool = False
    use_wikidata: bool = False

    use_rag: bool = False

    use_google_places: bool = False

    use_weather: bool = False
    use_maps: bool = False

    use_official_sources: bool = False

    must_be_fresh: bool = False

    metadata_filters: dict[str, Any] = field(
        default_factory=dict,
    )

    geographic_constraints: dict[str, Any] = field(
        default_factory=dict,
    )

    rationale: tuple[str, ...] = ()


@dataclass(slots=True)
class TravelQuery:
    """
    Canonical representation of a user's travel request.

    This becomes the central contract between:

        input processing
            ↓
        query understanding
            ↓
        retrieval
            ↓
        agents
            ↓
        response generation
    """

    # ------------------------------------------------------
    # Original user input
    # ------------------------------------------------------

    raw_query: str

    normalized_query: str = ""

    rewritten_query: str = ""

    # ------------------------------------------------------
    # Language
    # ------------------------------------------------------

    language: str | None = None

    languages: tuple[str, ...] = ()

    script: str | None = None

    transliterated_query: str | None = None

    # ------------------------------------------------------
    # Intent
    # ------------------------------------------------------

    intent: str = "unknown"

    sub_intents: tuple[str, ...] = ()

    # ------------------------------------------------------
    # Entities
    # ------------------------------------------------------

    entities: tuple[QueryEntity, ...] = ()

    origin: QueryEntity | None = None

    destination: QueryEntity | None = None

    # ------------------------------------------------------
    # Travel requirements
    # ------------------------------------------------------

    dates: TravelDateRange | None = None

    duration_days: int | None = None

    duration_nights: int | None = None

    traveler_count: int | None = None

    # ------------------------------------------------------
    # Budget
    # ------------------------------------------------------

    budget_amount: float | None = None

    budget_currency: str | None = None

    budget_level: str | None = None

    # ------------------------------------------------------
    # Preferences / constraints
    # ------------------------------------------------------

    preferences: tuple[TravelConstraint, ...] = ()

    constraints: tuple[TravelConstraint, ...] = ()

    exclusions: tuple[TravelConstraint, ...] = ()

    # ------------------------------------------------------
    # Query processing
    # ------------------------------------------------------

    spelling_corrections: dict[str, str] = field(
        default_factory=dict,
    )

    abbreviation_resolutions: dict[str, str] = field(
        default_factory=dict,
    )

    expanded_queries: tuple[str, ...] = ()

    ambiguities: tuple[QueryAmbiguity, ...] = ()

    missing_information: tuple[str, ...] = ()

    tasks: tuple[QueryTask, ...] = ()

    # ------------------------------------------------------
    # Planning
    # ------------------------------------------------------

    retrieval_plan: RetrievalPlan | None = None

    required_agents: tuple[str, ...] = ()

    required_tools: tuple[str, ...] = ()

    action_level: ActionLevel = ActionLevel.READ

    confirmation_required: bool = False

    # ------------------------------------------------------
    # Confidence
    # ------------------------------------------------------

    confidence: float = 0.0

    confidence_level: QueryConfidence = QueryConfidence.MEDIUM

    # ------------------------------------------------------
    # Context
    # ------------------------------------------------------

    conversation_used: bool = False

    personalization_used: bool = False

    active_trip_used: bool = False

    past_trip_used: bool = False

    # ------------------------------------------------------
    # Debug / observability
    # ------------------------------------------------------

    processing_steps: tuple[str, ...] = ()

    warnings: tuple[str, ...] = ()