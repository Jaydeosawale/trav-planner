from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Protocol, Sequence

from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.destination.service import DestinationService
from app.modules.place.service import PlaceService
from app.services.ai.contracts import RetrievalPlan
from app.services.ai.retrieval import HybridRetriever

from .candidate_ranker import (
    DiscoveryCandidateRanker,
    DiscoveryRankingContext,
    RankedDiscoveryCandidate,
)
from .entity_resolver import EntityResolver
from .source_merger import (
    DiscoveryCandidate,
    DiscoverySourceMerger,
    DiscoverySourceNormalizer,
)


class LiveDiscoveryProvider(Protocol):
    """
    Adapter contract for Google Places, OSM or similar live sources.
    """

    async def search(
        self,
        query: str,
        *,
        entity_type: str | None = None,
        latitude: float | None = None,
        longitude: float | None = None,
        limit: int = 10,
    ) -> Sequence[dict[str, Any]]:
        ...


@dataclass(slots=True)
class DiscoveryResult:
    """
    Discovery output ready for an agent or API layer.
    """

    ranked: tuple[RankedDiscoveryCandidate, ...]
    candidates: tuple[DiscoveryCandidate, ...]
    sources_used: tuple[str, ...]
    metadata: dict[str, Any]


class DestinationDiscoveryService:
    """
    Destination/place discovery pipeline.

    Sources:
        - internal PostgreSQL/CMS destinations
        - internal PostgreSQL/CMS places
        - optional hybrid RAG retriever
        - optional Google Places adapter
        - optional OSM adapter

    The service normalizes all source results, resolves duplicates,
    then ranks entities with privacy-preserving context.
    """

    def __init__(
        self,
        *,
        place_service: PlaceService | None = None,
        destination_service: DestinationService | None = None,
        hybrid_retriever: HybridRetriever | None = None,
        google_places: LiveDiscoveryProvider | None = None,
        osm: LiveDiscoveryProvider | None = None,
        ranker: DiscoveryCandidateRanker | None = None,
    ) -> None:
        self.place_service = place_service or PlaceService()
        self.destination_service = (
            destination_service or DestinationService()
        )
        self.hybrid_retriever = hybrid_retriever
        self.google_places = google_places
        self.osm = osm
        self.ranker = ranker or DiscoveryCandidateRanker()

    async def discover(
        self,
        db: AsyncSession,
        *,
        query: str,
        plan: RetrievalPlan,
        ranking_context: DiscoveryRankingContext,
        entity_type: str | None = None,
        limit: int = 10,
    ) -> DiscoveryResult:
        candidates: list[DiscoveryCandidate] = []
        sources_used: list[str] = []

        if plan.use_postgres:
            internal = await self._internal_candidates(
                db,
                query=query,
                entity_type=entity_type,
                limit=limit,
            )
            candidates.extend(internal)
            if internal:
                sources_used.append("postgres")

        if self.hybrid_retriever and (
            plan.use_bm25 or plan.use_vector
        ):
            rag = await self._rag_candidates(
                query=query,
                plan=plan,
                limit=limit,
            )
            candidates.extend(rag)
            if rag:
                sources_used.append("rag")

        if plan.use_google_places and self.google_places:
            google = await self._live_candidates(
                provider=self.google_places,
                source="google_places",
                query=query,
                entity_type=entity_type,
                context=ranking_context,
                limit=limit,
            )
            candidates.extend(google)
            if google:
                sources_used.append("google_places")

        if plan.use_osm and self.osm:
            osm = await self._live_candidates(
                provider=self.osm,
                source="osm",
                query=query,
                entity_type=entity_type,
                context=ranking_context,
                limit=limit,
            )
            candidates.extend(osm)
            if osm:
                sources_used.append("osm")

        merged = DiscoverySourceMerger.attach_source_score(
            DiscoverySourceMerger.merge(candidates)
        )
        entities = EntityResolver.resolve(merged)
        ranked = self.ranker.rank(
            entities,
            context=ranking_context,
            limit=limit,
        )

        return DiscoveryResult(
            ranked=tuple(ranked),
            candidates=tuple(merged),
            sources_used=tuple(dict.fromkeys(sources_used)),
            metadata={
                "candidate_count": len(merged),
                "resolved_entity_count": len(entities),
                "live_sources_configured": {
                    "google_places": self.google_places is not None,
                    "osm": self.osm is not None,
                },
            },
        )

    async def _internal_candidates(
        self,
        db: AsyncSession,
        *,
        query: str,
        entity_type: str | None,
        limit: int,
    ) -> list[DiscoveryCandidate]:
        candidates: list[DiscoveryCandidate] = []

        if entity_type in (None, "destination"):
            destinations = await self.destination_service.get_all(db)
            for destination in destinations[:limit]:
                candidates.append(
                    DiscoverySourceNormalizer.from_postgres(
                        {
                            "id": str(destination.id),
                            "name": destination.name,
                            "entity_type": "destination",
                            "city": (
                                destination.city.name
                                if destination.city is not None
                                else None
                            ),
                            "latitude": destination.latitude,
                            "longitude": destination.longitude,
                            "description": (
                                destination.description
                                or destination.short_description
                            ),
                            "score": self._text_score(
                                query,
                                destination.name,
                                destination.description,
                            ),
                            "is_current": destination.is_active,
                        }
                    )
                )

        place_type = None
        if entity_type not in (None, "destination", "place"):
            place_type = entity_type

        places, _ = await self.place_service.search(
            db=db,
            search=query,
            place_type=place_type,
            page=1,
            size=limit,
        )

        for place in places:
            candidates.append(
                DiscoverySourceNormalizer.from_postgres(
                    {
                        "id": str(place.id),
                        "name": place.name,
                        "entity_type": place.place_type,
                        "place_type": place.place_type,
                        "city": (
                            place.city.name
                            if place.city is not None
                            else None
                        ),
                        "latitude": place.latitude,
                        "longitude": place.longitude,
                        "description": (
                            place.description
                            or place.short_description
                        ),
                        "category": (
                            place.category.name
                            if place.category is not None
                            else None
                        ),
                        "rating": place.rating,
                        "price_level": place.price_level,
                        "score": self._text_score(
                            query,
                            place.name,
                            place.description,
                        ),
                        "is_current": place.is_active,
                    }
                )
            )

        return candidates

    async def _rag_candidates(
        self,
        *,
        query: str,
        plan: RetrievalPlan,
        limit: int,
    ) -> list[DiscoveryCandidate]:
        if self.hybrid_retriever is None:
            return []

        result = await self.hybrid_retriever.retrieve(
            query,
            plan=plan,
            final_limit=limit,
        )

        return [
            DiscoverySourceNormalizer.from_rag(
                {
                    "id": candidate.id,
                    "title": candidate.metadata.get("title"),
                    "name": candidate.metadata.get("name"),
                    "text": candidate.text,
                    "entity_type": candidate.metadata.get(
                        "entity_type",
                        "destination",
                    ),
                    "country": candidate.metadata.get("country"),
                    "state": candidate.metadata.get("state"),
                    "city": candidate.metadata.get("city"),
                    "latitude": candidate.metadata.get("latitude"),
                    "longitude": candidate.metadata.get("longitude"),
                    "category": candidate.metadata.get("category"),
                    "tags": candidate.metadata.get("tags"),
                    "source_url": candidate.metadata.get("source_url"),
                    "trust_level": candidate.metadata.get(
                        "trust_level",
                        "curated",
                    ),
                    "verified_at": candidate.metadata.get(
                        "verified_at"
                    ),
                    "score": candidate.score,
                }
            )
            for candidate in result.candidates
        ]

    async def _live_candidates(
        self,
        *,
        provider: LiveDiscoveryProvider,
        source: str,
        query: str,
        entity_type: str | None,
        context: DiscoveryRankingContext,
        limit: int,
    ) -> list[DiscoveryCandidate]:
        items = await provider.search(
            query,
            entity_type=entity_type,
            latitude=(
                context.latitude
                if context.location_consent
                else None
            ),
            longitude=(
                context.longitude
                if context.location_consent
                else None
            ),
            limit=limit,
        )

        normalizer = (
            DiscoverySourceNormalizer.from_google_places
            if source == "google_places"
            else DiscoverySourceNormalizer.from_osm
        )

        return [
            normalizer(item)
            for item in items
        ]

    @staticmethod
    def _text_score(
        query: str,
        *values: object,
    ) -> float:
        query_tokens = {
            token
            for token in query.lower().split()
            if token
        }

        if not query_tokens:
            return 0.5

        haystack = " ".join(
            str(value).lower()
            for value in values
            if value
        )

        overlap = sum(
            1
            for token in query_tokens
            if token in haystack
        )

        return min(overlap / len(query_tokens), 1.0)


__all__ = [
    "DestinationDiscoveryService",
    "DiscoveryResult",
    "LiveDiscoveryProvider",
]
