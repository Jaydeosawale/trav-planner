from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Iterable


# ==========================================================
# NORMALIZED DISCOVERY CANDIDATE
# ==========================================================

@dataclass(slots=True)
class DiscoveryCandidate:
    """
    Common representation for any travel destination/place.

    All discovery sources are converted into this structure
    before filtering, deduplication and ranking.
    """

    # Stable internal candidate identifier.
    candidate_id: str

    # Human-readable name.
    name: str

    # destination | place | hotel | restaurant | cafe | attraction
    entity_type: str

    # Source system:
    # postgres | rag | google_places | osm
    source: str

    # ------------------------------------------------------
    # Location
    # ------------------------------------------------------

    country: str | None = None

    state: str | None = None

    city: str | None = None

    latitude: float | None = None

    longitude: float | None = None

    # ------------------------------------------------------
    # Descriptive data
    # ------------------------------------------------------

    description: str | None = None

    category: str | None = None

    tags: tuple[str, ...] = ()

    # ------------------------------------------------------
    # Source / quality information
    # ------------------------------------------------------

    source_url: str | None = None

    source_id: str | None = None

    trust_level: str = "unknown"

    is_current: bool = True

    last_verified_at: str | None = None

    # ------------------------------------------------------
    # Ranking signals
    # ------------------------------------------------------

    retrieval_score: float = 0.0

    popularity_score: float = 0.0

    personalization_score: float = 0.0

    geographic_score: float = 0.0

    source_score: float = 0.0

    final_score: float = 0.0

    # ------------------------------------------------------
    # Additional normalized metadata
    # ------------------------------------------------------

    metadata: dict[str, Any] = field(
        default_factory=dict,
    )


# ==========================================================
# SOURCE NORMALIZER
# ==========================================================

class DiscoverySourceNormalizer:
    """
    Converts provider-specific dictionaries into
    DiscoveryCandidate objects.

    This keeps Google/OSM/PostgreSQL/RAG implementation details
    outside the ranking layer.
    """

    # ======================================================
    # POSTGRES / CMS
    # ======================================================

    @staticmethod
    def from_postgres(
        item: dict[str, Any],
    ) -> DiscoveryCandidate:
        return DiscoveryCandidate(
            candidate_id=(
                f"postgres:"
                f"{item.get('id') or item.get('name')}"
            ),

            name=str(
                item.get("name")
                or "Unknown place"
            ),

            entity_type=str(
                item.get("entity_type")
                or item.get("place_type")
                or "place"
            ),

            source="postgres",

            country=item.get("country"),

            state=item.get("state"),

            city=item.get("city"),

            latitude=(
                DiscoverySourceNormalizer._float(
                    item.get("latitude")
                )
            ),

            longitude=(
                DiscoverySourceNormalizer._float(
                    item.get("longitude")
                )
            ),

            description=(
                item.get("description")
                or item.get("short_description")
            ),

            category=item.get("category"),

            tags=(
                DiscoverySourceNormalizer._strings(
                    item.get("tags")
                )
            ),

            source_url=item.get("source_url"),

            source_id=(
                str(item["id"])
                if item.get("id") is not None
                else None
            ),

            trust_level="curated",

            is_current=bool(
                item.get("is_current", True)
            ),

            last_verified_at=item.get(
                "last_verified_at"
            ),

            retrieval_score=(
                DiscoverySourceNormalizer._float(
                    item.get("score")
                )
                or 0.0
            ),

            metadata={
                **item,
                "source_type": "postgres",
            },
        )

    # ======================================================
    # RAG
    # ======================================================

    @staticmethod
    def from_rag(
        item: dict[str, Any],
    ) -> DiscoveryCandidate:
        return DiscoveryCandidate(
            candidate_id=(
                f"rag:"
                f"{item.get('id') or item.get('document_id') or item.get('name')}"
            ),

            name=str(
                item.get("name")
                or item.get("title")
                or "Unknown destination"
            ),

            entity_type=str(
                item.get("entity_type")
                or "destination"
            ),

            source="rag",

            country=item.get("country"),

            state=item.get("state"),

            city=item.get("city"),

            latitude=(
                DiscoverySourceNormalizer._float(
                    item.get("latitude")
                )
            ),

            longitude=(
                DiscoverySourceNormalizer._float(
                    item.get("longitude")
                )
            ),

            description=(
                item.get("description")
                or item.get("text")
            ),

            category=item.get("category"),

            tags=(
                DiscoverySourceNormalizer._strings(
                    item.get("tags")
                )
            ),

            source_url=item.get("source_url"),

            source_id=(
                str(
                    item.get("id")
                    or item.get("document_id")
                )
                if (
                    item.get("id") is not None
                    or item.get("document_id") is not None
                )
                else None
            ),

            trust_level=str(
                item.get(
                    "trust_level",
                    "curated",
                )
            ),

            is_current=bool(
                item.get(
                    "is_current",
                    True,
                )
            ),

            last_verified_at=(
                item.get("verified_at")
                or item.get("last_verified_at")
            ),

            retrieval_score=(
                DiscoverySourceNormalizer._float(
                    item.get("score")
                )
                or 0.0
            ),

            metadata={
                **item,
                "source_type": "rag",
            },
        )

    # ======================================================
    # GOOGLE PLACES
    # ======================================================

    @staticmethod
    def from_google_places(
        item: dict[str, Any],
    ) -> DiscoveryCandidate:
        """
        Normalize Google Places output.

        Keep this adapter independent of the exact SDK response;
        the Google integration can convert its native response
        into this dictionary first.
        """

        location = item.get(
            "location",
            {},
        )

        return DiscoveryCandidate(
            candidate_id=(
                f"google:"
                f"{item.get('place_id') or item.get('id') or item.get('name')}"
            ),

            name=str(
                item.get("name")
                or "Unknown place"
            ),

            entity_type=str(
                item.get(
                    "entity_type",
                    "place",
                )
            ),

            source="google_places",

            country=item.get("country"),

            state=item.get("state"),

            city=item.get("city"),

            latitude=(
                DiscoverySourceNormalizer._float(
                    item.get("latitude")
                    or location.get("latitude")
                )
            ),

            longitude=(
                DiscoverySourceNormalizer._float(
                    item.get("longitude")
                    or location.get("longitude")
                )
            ),

            description=(
                item.get("description")
                or item.get("editorial_summary")
            ),

            category=item.get("category"),

            tags=(
                DiscoverySourceNormalizer._strings(
                    item.get("tags")
                    or item.get("types")
                )
            ),

            source_url=item.get(
                "google_maps_url"
            ),

            source_id=(
                str(
                    item.get("place_id")
                    or item.get("id")
                )
                if (
                    item.get("place_id") is not None
                    or item.get("id") is not None
                )
                else None
            ),

            trust_level="live_provider",

            is_current=True,

            last_verified_at=item.get(
                "retrieved_at"
            ),

            retrieval_score=(
                DiscoverySourceNormalizer._float(
                    item.get("score")
                )
                or 0.0
            ),

            popularity_score=(
                DiscoverySourceNormalizer._float(
                    item.get("rating")
                )
                or 0.0
            ),

            metadata={
                **item,
                "source_type": "google_places",
            },
        )

    # ======================================================
    # OPENSTREETMAP
    # ======================================================

    @staticmethod
    def from_osm(
        item: dict[str, Any],
    ) -> DiscoveryCandidate:
        return DiscoveryCandidate(
            candidate_id=(
                f"osm:"
                f"{item.get('osm_id') or item.get('id') or item.get('name')}"
            ),

            name=str(
                item.get("name")
                or "Unknown place"
            ),

            entity_type=str(
                item.get(
                    "entity_type",
                    "place",
                )
            ),

            source="osm",

            country=item.get("country"),

            state=item.get("state"),

            city=item.get("city"),

            latitude=(
                DiscoverySourceNormalizer._float(
                    item.get("latitude")
                )
            ),

            longitude=(
                DiscoverySourceNormalizer._float(
                    item.get("longitude")
                )
            ),

            description=item.get(
                "description"
            ),

            category=(
                item.get("category")
                or item.get("tourism")
                or item.get("amenity")
            ),

            tags=(
                DiscoverySourceNormalizer._strings(
                    item.get("tags")
                )
            ),

            source_url=item.get(
                "source_url"
            ),

            source_id=(
                str(
                    item.get("osm_id")
                    or item.get("id")
                )
                if (
                    item.get("osm_id") is not None
                    or item.get("id") is not None
                )
                else None
            ),

            trust_level="open_source",

            is_current=True,

            last_verified_at=item.get(
                "retrieved_at"
            ),

            retrieval_score=(
                DiscoverySourceNormalizer._float(
                    item.get("score")
                )
                or 0.0
            ),

            metadata={
                **item,
                "source_type": "osm",
            },
        )

    # ======================================================
    # HELPERS
    # ======================================================

    @staticmethod
    def _float(
        value: Any,
    ) -> float | None:
        if value is None:
            return None

        try:
            return float(value)
        except (
            TypeError,
            ValueError,
        ):
            return None

    @staticmethod
    def _strings(
        value: Any,
    ) -> tuple[str, ...]:
        if value is None:
            return ()

        if isinstance(
            value,
            str,
        ):
            return (
                value,
            )

        if isinstance(
            value,
            Iterable,
        ):
            result: list[str] = []

            for item in value:
                if item is None:
                    continue

                result.append(
                    str(item)
                )

            return tuple(
                result
            )

        return (
            str(value),
        )


# ==========================================================
# SOURCE MERGER
# ==========================================================

class DiscoverySourceMerger:
    """
    Combines candidates from all discovery sources.

    It deliberately does NOT decide which candidate is best.
    That is the ranker's responsibility.
    """

    @staticmethod
    def merge(
        candidates: Iterable[
            DiscoveryCandidate
        ],
    ) -> list[
        DiscoveryCandidate
    ]:
        result: list[
            DiscoveryCandidate
        ] = []

        for candidate in candidates:
            result.append(
                candidate
            )

        return result

    # ======================================================
    # SOURCE PRIORITY
    # ======================================================

    @staticmethod
    def source_priority(
        source: str,
    ) -> float:
        """
        Base trust/priority only.

        This is NOT the final ranking.

        Curated internal data gets strong preference for
        Trav Planner-specific recommendations.

        Live Google data gets strong preference for current
        real-world places.

        RAG is useful for semantic/knowledge discovery.

        OSM is valuable as an open-source geographic supplement.
        """

        priorities = {
            "postgres": 1.00,
            "google_places": 0.95,
            "rag": 0.85,
            "osm": 0.80,
        }

        return priorities.get(
            source,
            0.50,
        )

    @classmethod
    def attach_source_score(
        cls,
        candidates: Iterable[
            DiscoveryCandidate
        ],
    ) -> list[
        DiscoveryCandidate
    ]:
        result: list[
            DiscoveryCandidate
        ] = []

        for candidate in candidates:
            priority = cls.source_priority(
                candidate.source
            )

            result.append(
                DiscoveryCandidate(
                    candidate_id=candidate.candidate_id,
                    name=candidate.name,
                    entity_type=candidate.entity_type,
                    source=candidate.source,

                    country=candidate.country,
                    state=candidate.state,
                    city=candidate.city,

                    latitude=candidate.latitude,
                    longitude=candidate.longitude,

                    description=candidate.description,
                    category=candidate.category,
                    tags=candidate.tags,

                    source_url=candidate.source_url,
                    source_id=candidate.source_id,

                    trust_level=candidate.trust_level,
                    is_current=candidate.is_current,
                    last_verified_at=candidate.last_verified_at,

                    retrieval_score=candidate.retrieval_score,

                    popularity_score=candidate.popularity_score,
                    personalization_score=candidate.personalization_score,
                    geographic_score=candidate.geographic_score,

                    source_score=priority,

                    final_score=candidate.final_score,

                    metadata=candidate.metadata,
                )
            )

        return result

    # ======================================================
    # CANONICAL KEY
    # ======================================================

    @staticmethod
    def canonical_key(
        candidate: DiscoveryCandidate,
    ) -> str:
        """
        Produce a rough cross-source matching key.

        EntityResolver will perform the more sophisticated
        duplicate/identity resolution later.
        """

        name = (
            candidate.name
            .lower()
            .strip()
        )

        name = " ".join(
            name.split()
        )

        city = (
            candidate.city
            or ""
        ).lower().strip()

        return (
            f"{name}|{city}"
        )


__all__ = [
    "DiscoveryCandidate",
    "DiscoverySourceNormalizer",
    "DiscoverySourceMerger",
]
