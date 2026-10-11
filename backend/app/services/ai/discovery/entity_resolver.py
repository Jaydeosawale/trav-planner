from __future__ import annotations

import math
import re
import unicodedata
from dataclasses import dataclass, field
from difflib import SequenceMatcher
from typing import Iterable

from .source_merger import DiscoveryCandidate


# ==========================================================
# RESOLVED ENTITY
# ==========================================================

@dataclass(slots=True)
class ResolvedEntity:
    """
    Canonical representation of one real-world entity.

    Multiple providers can contribute evidence to the same entity.
    """

    canonical_id: str

    canonical_name: str

    entity_type: str

    country: str | None = None

    state: str | None = None

    city: str | None = None

    latitude: float | None = None

    longitude: float | None = None

    description: str | None = None

    category: str | None = None

    tags: tuple[str, ...] = ()

    source_candidates: tuple[
        DiscoveryCandidate,
        ...
    ] = ()

    sources: tuple[str, ...] = ()

    source_ids: tuple[str, ...] = ()

    confidence: float = 0.0

    metadata: dict = field(
        default_factory=dict,
    )


# ==========================================================
# MATCH RESULT
# ==========================================================

@dataclass(slots=True)
class EntityMatch:
    candidate_id: str

    matched_canonical_id: str | None

    score: float

    reasons: tuple[str, ...] = ()


# ==========================================================
# ENTITY RESOLVER
# ==========================================================

class EntityResolver:
    """
    Cross-source entity resolution.

    Matching uses several signals:

        normalized name
        aliases
        city
        country
        category/type
        geographic distance

    It deliberately does NOT rely only on name similarity.
    """

    # Conservative thresholds.
    HIGH_CONFIDENCE = 0.88

    MEDIUM_CONFIDENCE = 0.74

    MINIMUM_MATCH = 0.68

    # ======================================================
    # TEXT NORMALIZATION
    # ======================================================

    @staticmethod
    def normalize_text(
        value: str | None,
    ) -> str:
        if not value:
            return ""

        text = unicodedata.normalize(
            "NFKD",
            value,
        )

        text = (
            text.encode(
                "ascii",
                "ignore",
            )
            .decode("ascii")
        )

        text = text.lower()

        # Common punctuation becomes spaces.
        text = re.sub(
            r"[^a-z0-9\s]",
            " ",
            text,
        )

        # Common travel/place noise words.
        text = re.sub(
            r"\b("
            r"the|hotel|resort|restaurant|"
            r"cafe|café|guesthouse|"
            r"lodge|inn"
            r")\b",
            " ",
            text,
        )

        text = re.sub(
            r"\s+",
            " ",
            text,
        ).strip()

        return text

    # ======================================================
    # TOKENIZATION
    # ======================================================

    @classmethod
    def tokens(
        cls,
        value: str | None,
    ) -> set[str]:
        normalized = cls.normalize_text(
            value,
        )

        if not normalized:
            return set()

        return set(
            normalized.split()
        )

    # ======================================================
    # NAME SIMILARITY
    # ======================================================

    @classmethod
    def name_similarity(
        cls,
        first: str | None,
        second: str | None,
    ) -> float:
        a = cls.normalize_text(
            first,
        )

        b = cls.normalize_text(
            second,
        )

        if not a or not b:
            return 0.0

        if a == b:
            return 1.0

        sequence_score = SequenceMatcher(
            None,
            a,
            b,
        ).ratio()

        a_tokens = cls.tokens(
            first,
        )

        b_tokens = cls.tokens(
            second,
        )

        if not a_tokens or not b_tokens:
            token_score = 0.0

        else:
            intersection = (
                a_tokens & b_tokens
            )

            union = (
                a_tokens | b_tokens
            )

            token_score = (
                len(intersection)
                / len(union)
            )

        # Sequence similarity is useful for names with
        # slightly different word ordering; token overlap
        # catches "Taj Exotica" vs "Taj Exotica Resort".
        return (
            sequence_score * 0.65
            + token_score * 0.35
        )

    # ======================================================
    # LOCATION SIMILARITY
    # ======================================================

    @classmethod
    def location_similarity(
        cls,
        first: DiscoveryCandidate,
        second: DiscoveryCandidate,
    ) -> float:

        score = 0.0

        # --------------------------------------------------
        # City
        # --------------------------------------------------

        first_city = cls.normalize_text(
            first.city,
        )

        second_city = cls.normalize_text(
            second.city,
        )

        if (
            first_city
            and second_city
        ):
            if first_city == second_city:
                score += 0.40

        # --------------------------------------------------
        # State
        # --------------------------------------------------

        first_state = cls.normalize_text(
            first.state,
        )

        second_state = cls.normalize_text(
            second.state,
        )

        if (
            first_state
            and second_state
            and first_state == second_state
        ):
            score += 0.15

        # --------------------------------------------------
        # Country
        # --------------------------------------------------

        first_country = cls.normalize_text(
            first.country,
        )

        second_country = cls.normalize_text(
            second.country,
        )

        if (
            first_country
            and second_country
            and first_country == second_country
        ):
            score += 0.15

        # --------------------------------------------------
        # Coordinates
        # --------------------------------------------------

        distance = cls.distance_km(
            first.latitude,
            first.longitude,
            second.latitude,
            second.longitude,
        )

        if distance is not None:

            if distance <= 0.1:
                score += 0.40

            elif distance <= 0.5:
                score += 0.30

            elif distance <= 2.0:
                score += 0.18

            elif distance <= 5.0:
                score += 0.08

        return min(
            score,
            1.0,
        )

    # ======================================================
    # TYPE SIMILARITY
    # ======================================================

    @classmethod
    def type_similarity(
        cls,
        first: DiscoveryCandidate,
        second: DiscoveryCandidate,
    ) -> float:

        a = cls.normalize_text(
            first.entity_type,
        )

        b = cls.normalize_text(
            second.entity_type,
        )

        if not a or not b:
            return 0.0

        if a == b:
            return 1.0

        # Related categories.
        related = {
            frozenset(
                ("place", "attraction")
            ),
            frozenset(
                ("hotel", "resort")
            ),
            frozenset(
                ("restaurant", "cafe")
            ),
            frozenset(
                ("destination", "city")
            ),
        }

        if frozenset((a, b)) in related:
            return 0.65

        return 0.0

    # ======================================================
    # CATEGORY SIMILARITY
    # ======================================================

    @classmethod
    def category_similarity(
        cls,
        first: DiscoveryCandidate,
        second: DiscoveryCandidate,
    ) -> float:

        a = cls.normalize_text(
            first.category,
        )

        b = cls.normalize_text(
            second.category,
        )

        if not a or not b:
            return 0.0

        if a == b:
            return 1.0

        return cls.name_similarity(
            a,
            b,
        )

    # ======================================================
    # COMPLETE MATCH SCORE
    # ======================================================

    @classmethod
    def match_score(
        cls,
        first: DiscoveryCandidate,
        second: DiscoveryCandidate,
    ) -> tuple[
        float,
        tuple[str, ...],
    ]:

        reasons: list[str] = []

        name_score = cls.name_similarity(
            first.name,
            second.name,
        )

        location_score = (
            cls.location_similarity(
                first,
                second,
            )
        )

        type_score = cls.type_similarity(
            first,
            second,
        )

        category_score = (
            cls.category_similarity(
                first,
                second,
            )
        )

        # --------------------------------------------------
        # Weighted score
        # --------------------------------------------------

        score = (
            name_score * 0.55
            + location_score * 0.25
            + type_score * 0.10
            + category_score * 0.10
        )

        # --------------------------------------------------
        # Strong signals
        # --------------------------------------------------

        if name_score >= 0.90:
            reasons.append(
                "high_name_similarity"
            )

        if location_score >= 0.70:
            reasons.append(
                "same_location"
            )

        if type_score >= 0.90:
            reasons.append(
                "same_entity_type"
            )

        if category_score >= 0.90:
            reasons.append(
                "same_category"
            )

        # Coordinates within 100m are a very strong signal.
        distance = cls.distance_km(
            first.latitude,
            first.longitude,
            second.latitude,
            second.longitude,
        )

        if (
            distance is not None
            and distance <= 0.1
        ):
            score += 0.12

            reasons.append(
                "coordinates_within_100m"
            )

        return (
            min(score, 1.0),
            tuple(reasons),
        )

    # ======================================================
    # HAVERSINE DISTANCE
    # ======================================================

    @staticmethod
    def distance_km(
        latitude_1: float | None,
        longitude_1: float | None,
        latitude_2: float | None,
        longitude_2: float | None,
    ) -> float | None:

        if any(
            value is None
            for value in (
                latitude_1,
                longitude_1,
                latitude_2,
                longitude_2,
            )
        ):
            return None

        lat1 = math.radians(
            float(latitude_1)
        )

        lon1 = math.radians(
            float(longitude_1)
        )

        lat2 = math.radians(
            float(latitude_2)
        )

        lon2 = math.radians(
            float(longitude_2)
        )

        dlat = lat2 - lat1
        dlon = lon2 - lon1

        a = (
            math.sin(dlat / 2) ** 2
            + math.cos(lat1)
            * math.cos(lat2)
            * math.sin(dlon / 2) ** 2
        )

        c = 2 * math.atan2(
            math.sqrt(a),
            math.sqrt(1 - a),
        )

        return 6371.0 * c

    # ======================================================
    # FIND MATCH
    # ======================================================

    @classmethod
    def find_match(
        cls,
        candidate: DiscoveryCandidate,
        canonical_entities: Iterable[
            ResolvedEntity
        ],
    ) -> EntityMatch:

        best_id: str | None = None

        best_score = 0.0

        best_reasons: tuple[str, ...] = ()

        for entity in canonical_entities:

            # Compare against the strongest existing source
            # candidate for the canonical entity.
            for existing in (
                entity.source_candidates
            ):

                score, reasons = (
                    cls.match_score(
                        candidate,
                        existing,
                    )
                )

                if score > best_score:
                    best_score = score

                    best_id = (
                        entity.canonical_id
                    )

                    best_reasons = reasons

        return EntityMatch(
            candidate_id=candidate.candidate_id,

            matched_canonical_id=(
                best_id
                if best_score >= cls.MINIMUM_MATCH
                else None
            ),

            score=best_score,

            reasons=best_reasons,
        )

    # ======================================================
    # CANONICAL NAME
    # ======================================================

    @classmethod
    def choose_canonical_name(
        cls,
        candidates: list[
            DiscoveryCandidate
        ],
    ) -> str:

        if not candidates:
            return "Unknown place"

        # Prefer curated internal name when available.
        curated = [
            candidate
            for candidate in candidates
            if candidate.source == "postgres"
        ]

        if curated:
            return curated[0].name

        # Next prefer Google because it normally has a
        # consumer-facing canonical place name.
        google = [
            candidate
            for candidate in candidates
            if candidate.source
            == "google_places"
        ]

        if google:
            return google[0].name

        # Otherwise use the most descriptive name.
        return max(
            candidates,
            key=lambda candidate: len(
                candidate.name
            ),
        ).name

    # ======================================================
    # MERGE ENTITY
    # ======================================================

    @classmethod
    def merge_entity(
        cls,
        candidates: list[
            DiscoveryCandidate
        ],
    ) -> ResolvedEntity:

        if not candidates:
            raise ValueError(
                "Cannot merge an empty candidate list."
            )

        primary = candidates[0]

        canonical_name = (
            cls.choose_canonical_name(
                candidates,
            )
        )

        # --------------------------------------------------
        # Location fallback
        # --------------------------------------------------

        country = cls._first_value(
            candidates,
            "country",
        )

        state = cls._first_value(
            candidates,
            "state",
        )

        city = cls._first_value(
            candidates,
            "city",
        )

        latitude = cls._first_numeric(
            candidates,
            "latitude",
        )

        longitude = cls._first_numeric(
            candidates,
            "longitude",
        )

        # --------------------------------------------------
        # Description
        # --------------------------------------------------

        description = cls._best_description(
            candidates,
        )

        # --------------------------------------------------
        # Category
        # --------------------------------------------------

        category = cls._first_value(
            candidates,
            "category",
        )

        # --------------------------------------------------
        # Tags
        # --------------------------------------------------

        tags: list[str] = []

        for candidate in candidates:
            for tag in candidate.tags:
                if tag not in tags:
                    tags.append(tag)

        # --------------------------------------------------
        # Sources
        # --------------------------------------------------

        sources = tuple(
            dict.fromkeys(
                candidate.source
                for candidate in candidates
            )
        )

        source_ids = tuple(
            dict.fromkeys(
                candidate.source_id
                for candidate in candidates
                if candidate.source_id
            )
        )

        # --------------------------------------------------
        # Confidence
        # --------------------------------------------------

        confidence = (
            cls._entity_confidence(
                candidates,
            )
        )

        return ResolvedEntity(
            canonical_id=(
                f"entity:{primary.candidate_id}"
            ),

            canonical_name=canonical_name,

            entity_type=primary.entity_type,

            country=country,

            state=state,

            city=city,

            latitude=latitude,

            longitude=longitude,

            description=description,

            category=category,

            tags=tuple(tags),

            source_candidates=tuple(
                candidates
            ),

            sources=sources,

            source_ids=source_ids,

            confidence=confidence,

            metadata={
                "source_count": len(
                    candidates
                ),
            },
        )

    # ======================================================
    # RESOLVE ALL
    # ======================================================

    @classmethod
    def resolve(
        cls,
        candidates: Iterable[
            DiscoveryCandidate
        ],
    ) -> list[
        ResolvedEntity
    ]:

        ordered = list(
            candidates
        )

        entities: list[
            ResolvedEntity
        ] = []

        # --------------------------------------------------
        # Process curated/live sources first.
        # --------------------------------------------------

        source_order = {
            "postgres": 0,
            "google_places": 1,
            "rag": 2,
            "osm": 3,
        }

        ordered.sort(
            key=lambda candidate: (
                source_order.get(
                    candidate.source,
                    99,
                ),
                -candidate.retrieval_score,
            )
        )

        for candidate in ordered:

            match = cls.find_match(
                candidate,
                entities,
            )

            if (
                match.matched_canonical_id
                is None
            ):
                entities.append(
                    cls.merge_entity(
                        [candidate]
                    )
                )

                continue

            # --------------------------------------------------
            # Add candidate to existing entity.
            # --------------------------------------------------

            for index, entity in enumerate(
                entities
            ):

                if (
                    entity.canonical_id
                    != match.matched_canonical_id
                ):
                    continue

                merged_candidates = [
                    *entity.source_candidates,
                    candidate,
                ]

                entities[index] = (
                    cls.merge_entity(
                        merged_candidates
                    )
                )

                break

        return entities

    # ======================================================
    # HELPERS
    # ======================================================

    @staticmethod
    def _first_value(
        candidates: list[
            DiscoveryCandidate
        ],
        field_name: str,
    ):

        for candidate in candidates:
            value = getattr(
                candidate,
                field_name,
                None,
            )

            if value not in (
                None,
                "",
            ):
                return value

        return None

    @staticmethod
    def _first_numeric(
        candidates: list[
            DiscoveryCandidate
        ],
        field_name: str,
    ) -> float | None:

        for candidate in candidates:
            value = getattr(
                candidate,
                field_name,
                None,
            )

            if value is not None:
                try:
                    return float(value)
                except (
                    TypeError,
                    ValueError,
                ):
                    continue

        return None

    @staticmethod
    def _best_description(
        candidates: list[
            DiscoveryCandidate
        ],
    ) -> str | None:

        descriptions = [
            candidate.description.strip()
            for candidate in candidates
            if candidate.description
            and candidate.description.strip()
        ]

        if not descriptions:
            return None

        return max(
            descriptions,
            key=len,
        )

    @classmethod
    def _entity_confidence(
        cls,
        candidates: list[
            DiscoveryCandidate
        ],
    ) -> float:

        if len(candidates) == 1:
            return 0.60

        # Multiple independent sources agreeing on an entity
        # increases confidence.
        unique_sources = {
            candidate.source
            for candidate in candidates
        }

        confidence = 0.60

        confidence += min(
            len(unique_sources) * 0.10,
            0.30,
        )

        # Exact/near-exact coordinates increase confidence.
        for first_index, first in enumerate(
            candidates
        ):
            for second in candidates[
                first_index + 1:
            ]:
                distance = cls.distance_km(
                    first.latitude,
                    first.longitude,
                    second.latitude,
                    second.longitude,
                )

                if (
                    distance is not None
                    and distance <= 0.1
                ):
                    confidence += 0.08

                    break

        return min(
            confidence,
            1.0,
        )


__all__ = [
    "ResolvedEntity",
    "EntityMatch",
    "EntityResolver",
]
