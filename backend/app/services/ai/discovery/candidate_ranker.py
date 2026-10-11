from __future__ import annotations

import math
import re
from dataclasses import dataclass
from typing import Iterable, Sequence

from .entity_resolver import EntityResolver, ResolvedEntity


# ==========================================================
# RANKING CONTEXT
# ==========================================================

@dataclass(slots=True)
class DiscoveryRankingContext:
    """
    Privacy-preserving ranking context.

    This contains derived travel signals rather than the user's
    complete profile or personal data.
    """

    query: str = ""

    origin_city: str | None = None

    origin_country: str | None = None

    preferred_interests: tuple[str, ...] = ()

    preferred_travel_styles: tuple[str, ...] = ()

    preferred_categories: tuple[str, ...] = ()

    # If location permission is available, the application can
    # provide coarse coordinates for geographic ranking.
    latitude: float | None = None

    longitude: float | None = None

    location_consent: bool = False

    # If true, prefer destinations the user has not recently
    # visited.
    avoid_recently_visited: bool = True

    recently_visited: tuple[str, ...] = ()


# ==========================================================
# RANKED RESULT
# ==========================================================

@dataclass(slots=True)
class RankedDiscoveryCandidate:
    entity: ResolvedEntity

    relevance_score: float

    source_score: float

    freshness_score: float

    popularity_score: float

    geographic_score: float

    personalization_score: float

    diversity_score: float

    final_score: float

    reasons: tuple[str, ...] = ()


# ==========================================================
# RANKER
# ==========================================================

class DiscoveryCandidateRanker:
    """
    Rank resolved destination/place entities.

    Ranking happens AFTER entity resolution.

    This prevents Google/OSM/RAG duplicates from receiving
    independent ranking positions.
    """

    # ======================================================
    # SOURCE WEIGHTS
    # ======================================================

    SOURCE_WEIGHTS = {
        "postgres": 1.00,
        "google_places": 0.95,
        "rag": 0.85,
        "osm": 0.80,
    }

    # ======================================================
    # MAIN RANK
    # ======================================================

    def rank(
        self,
        entities: Sequence[ResolvedEntity],
        *,
        context: DiscoveryRankingContext,
        limit: int = 10,
    ) -> list[RankedDiscoveryCandidate]:

        ranked: list[
            RankedDiscoveryCandidate
        ] = []

        for entity in entities:

            relevance = (
                self._relevance_score(
                    entity,
                    context,
                )
            )

            source = (
                self._source_score(
                    entity,
                )
            )

            freshness = (
                self._freshness_score(
                    entity,
                )
            )

            popularity = (
                self._popularity_score(
                    entity,
                )
            )

            geographic = (
                self._geographic_score(
                    entity,
                    context,
                )
            )

            personalization = (
                self._personalization_score(
                    entity,
                    context,
                )
            )

            diversity = (
                self._diversity_score(
                    entity,
                    ranked,
                )
            )

            # --------------------------------------------------
            # Final weighted score
            # --------------------------------------------------
            #
            # Relevance is the strongest signal.
            #
            # Source quality prevents weak/unknown sources
            # from automatically outranking trusted data.
            #
            # Personalization is meaningful but intentionally
            # not dominant.
            #
            # Geographic score only becomes useful when location
            # permission/context exists.
            # --------------------------------------------------

            final_score = (
                relevance * 0.30
                + source * 0.15
                + freshness * 0.10
                + popularity * 0.10
                + geographic * 0.15
                + personalization * 0.15
                + diversity * 0.05
            )

            reasons = (
                self._build_reasons(
                    entity,
                    relevance=relevance,
                    source=source,
                    freshness=freshness,
                    popularity=popularity,
                    geographic=geographic,
                    personalization=personalization,
                )
            )

            ranked.append(
                RankedDiscoveryCandidate(
                    entity=entity,
                    relevance_score=relevance,
                    source_score=source,
                    freshness_score=freshness,
                    popularity_score=popularity,
                    geographic_score=geographic,
                    personalization_score=personalization,
                    diversity_score=diversity,
                    final_score=min(
                        max(
                            final_score,
                            0.0,
                        ),
                        1.0,
                    ),
                    reasons=reasons,
                )
            )

        ranked.sort(
            key=lambda item: item.final_score,
            reverse=True,
        )

        return ranked[:limit]

    # ======================================================
    # RELEVANCE
    # ======================================================

    def _relevance_score(
        self,
        entity: ResolvedEntity,
        context: DiscoveryRankingContext,
    ) -> float:

        if not context.query:
            return 0.50

        query_tokens = self._tokens(
            context.query,
        )

        if not query_tokens:
            return 0.50

        entity_text = " ".join(
            value
            for value in (
                entity.canonical_name,
                entity.description or "",
                entity.category or "",
                *entity.tags,
                entity.city or "",
                entity.state or "",
                entity.country or "",
            )
            if value
        )

        entity_tokens = self._tokens(
            entity_text,
        )

        if not entity_tokens:
            return 0.0

        overlap = (
            len(
                query_tokens
                & entity_tokens
            )
            / len(query_tokens)
        )

        # Also compare the full entity name.
        name_similarity = (
            EntityResolver.name_similarity(
                context.query,
                entity.canonical_name,
            )
        )

        # The overlap signal is generally more useful for natural
        # language queries, while name similarity helps exact place
        # searches.
        return min(
            max(
                overlap * 0.65
                + name_similarity * 0.35,
                0.0,
            ),
            1.0,
        )

    # ======================================================
    # SOURCE
    # ======================================================

    def _source_score(
        self,
        entity: ResolvedEntity,
    ) -> float:

        if not entity.sources:
            return 0.50

        scores = [
            self.SOURCE_WEIGHTS.get(
                source,
                0.50,
            )
            for source in entity.sources
        ]

        strongest = max(scores)

        # Independent source agreement is useful.
        agreement_bonus = min(
            (len(entity.sources) - 1)
            * 0.05,
            0.15,
        )

        return min(
            strongest + agreement_bonus,
            1.0,
        )

    # ======================================================
    # FRESHNESS
    # ======================================================

    def _freshness_score(
        self,
        entity: ResolvedEntity,
    ) -> float:

        if not entity.source_candidates:
            return 0.50

        # Live providers are treated as fresher by default.
        live_sources = {
            "google_places",
            "osm",
        }

        if any(
            candidate.source in live_sources
            and candidate.is_current
            for candidate in entity.source_candidates
        ):
            return 0.95

        # Current internal/RAG content.
        if any(
            candidate.is_current
            for candidate in entity.source_candidates
        ):
            return 0.80

        return 0.40

    # ======================================================
    # POPULARITY
    # ======================================================

    def _popularity_score(
        self,
        entity: ResolvedEntity,
    ) -> float:

        values: list[float] = []

        for candidate in entity.source_candidates:

            # Google rating.
            rating = candidate.metadata.get(
                "rating",
            )

            if rating is not None:
                try:
                    values.append(
                        min(
                            max(
                                float(rating) / 5.0,
                                0.0,
                            ),
                            1.0,
                        )
                    )
                except (
                    TypeError,
                    ValueError,
                ):
                    pass

            # Existing popularity score.
            if candidate.popularity_score:
                values.append(
                    min(
                        max(
                            candidate.popularity_score,
                            0.0,
                        ),
                        1.0,
                    )
                )

        if not values:
            return 0.50

        return max(values)

    # ======================================================
    # GEOGRAPHIC RELEVANCE
    # ======================================================

    def _geographic_score(
        self,
        entity: ResolvedEntity,
        context: DiscoveryRankingContext,
    ) -> float:

        # Do not use location unless permission exists.
        if not context.location_consent:
            return 0.50

        # Exact/coarse coordinates.
        distance = EntityResolver.distance_km(
            context.latitude,
            context.longitude,
            entity.latitude,
            entity.longitude,
        )

        if distance is not None:

            # Nearby places get stronger scores.
            if distance <= 2:
                return 1.00

            if distance <= 5:
                return 0.90

            if distance <= 15:
                return 0.75

            if distance <= 50:
                return 0.60

            if distance <= 200:
                return 0.45

            return 0.25

        # Fall back to city/country matching.
        if (
            context.origin_city
            and entity.city
            and self._same_text(
                context.origin_city,
                entity.city,
            )
        ):
            return 0.85

        if (
            context.origin_country
            and entity.country
            and self._same_text(
                context.origin_country,
                entity.country,
            )
        ):
            return 0.65

        return 0.40

    # ======================================================
    # PERSONALIZATION
    # ======================================================

    def _personalization_score(
        self,
        entity: ResolvedEntity,
        context: DiscoveryRankingContext,
    ) -> float:

        signals: list[float] = []

        entity_text = self._normalize(
            " ".join(
                value
                for value in (
                    entity.canonical_name,
                    entity.description or "",
                    entity.category or "",
                    *entity.tags,
                )
                if value
            )
        )

        # --------------------------------------------------
        # Interests
        # --------------------------------------------------

        for interest in context.preferred_interests:

            if self._normalize(
                interest,
            ) in entity_text:
                signals.append(
                    1.0
                )

        # --------------------------------------------------
        # Travel styles
        # --------------------------------------------------

        for style in context.preferred_travel_styles:

            if self._normalize(
                style,
            ) in entity_text:
                signals.append(
                    0.90
                )

        # --------------------------------------------------
        # Categories
        # --------------------------------------------------

        if entity.category:

            for category in (
                context.preferred_categories
            ):
                if self._same_text(
                    entity.category,
                    category,
                ):
                    signals.append(
                        1.0
                    )

        # --------------------------------------------------
        # Recently visited
        # --------------------------------------------------

        if context.avoid_recently_visited:

            normalized_name = (
                self._normalize(
                    entity.canonical_name,
                )
            )

            for visited in (
                context.recently_visited
            ):
                if normalized_name == (
                    self._normalize(
                        visited,
                    )
                ):
                    # We don't eliminate the entity here.
                    # We penalize it so the user can still ask
                    # for it explicitly later.
                    signals.append(
                        0.0
                    )

        if not signals:
            return 0.50

        return sum(signals) / len(
            signals
        )

    # ======================================================
    # DIVERSITY
    # ======================================================

    @staticmethod
    def _diversity_score(
        entity: ResolvedEntity,
        previous: Sequence[
            RankedDiscoveryCandidate
        ],
    ) -> float:

        if not previous:
            return 1.0

        # Encourage different categories/cities among the
        # first few recommendations.
        for item in previous:

            existing = item.entity

            if (
                entity.category
                and existing.category
                and entity.category
                == existing.category
                and entity.city
                and existing.city
                and entity.city
                == existing.city
            ):
                return 0.35

        return 0.85

    # ======================================================
    # REASONS
    # ======================================================

    def _build_reasons(
        self,
        entity: ResolvedEntity,
        *,
        relevance: float,
        source: float,
        freshness: float,
        popularity: float,
        geographic: float,
        personalization: float,
    ) -> tuple[str, ...]:

        reasons: list[str] = []

        if relevance >= 0.75:
            reasons.append(
                "high_query_relevance"
            )

        if source >= 0.90:
            reasons.append(
                "trusted_source"
            )

        if len(entity.sources) >= 2:
            reasons.append(
                "multiple_sources_agree"
            )

        if freshness >= 0.90:
            reasons.append(
                "fresh_data"
            )

        if popularity >= 0.80:
            reasons.append(
                "popular"
            )

        if geographic >= 0.80:
            reasons.append(
                "geographically_relevant"
            )

        if personalization >= 0.75:
            reasons.append(
                "matches_preferences"
            )

        return tuple(
            reasons
        )

    # ======================================================
    # TEXT HELPERS
    # ======================================================

    @staticmethod
    def _normalize(
        value: str,
    ) -> str:

        value = value.lower()

        value = re.sub(
            r"[^a-z0-9\s]",
            " ",
            value,
        )

        value = re.sub(
            r"\s+",
            " ",
            value,
        )

        return value.strip()

    @classmethod
    def _tokens(
        cls,
        value: str,
    ) -> set[str]:

        normalized = cls._normalize(
            value,
        )

        if not normalized:
            return set()

        return set(
            normalized.split()
        )

    @classmethod
    def _same_text(
        cls,
        first: str,
        second: str,
    ) -> bool:

        return (
            cls._normalize(first)
            == cls._normalize(second)
        )


__all__ = [
    "DiscoveryRankingContext",
    "RankedDiscoveryCandidate",
    "DiscoveryCandidateRanker",
]
