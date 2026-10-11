from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Protocol, Sequence

from .contracts import (
    EvidenceRef,
    RetrievalPlan,
)


# ==========================================================
# RETRIEVAL CANDIDATE
# ==========================================================

@dataclass(slots=True)
class RetrievalCandidate:
    """
    A candidate returned by BM25/vector/other retrieval systems.
    """

    id: str

    text: str

    source_type: str

    score: float = 0.0

    metadata: dict[str, Any] = field(
        default_factory=dict,
    )

    # Original rank from the retrieval source.
    rank: int | None = None


# ==========================================================
# RETRIEVER INTERFACES
# ==========================================================

class KeywordRetriever(Protocol):
    """
    BM25 / lexical retriever contract.
    """

    async def search(
        self,
        query: str,
        *,
        limit: int = 20,
        filters: dict[str, Any] | None = None,
    ) -> Sequence[RetrievalCandidate]:
        ...


class VectorRetriever(Protocol):
    """
    Embedding/vector retriever contract.
    """

    async def search(
        self,
        query: str,
        *,
        limit: int = 20,
        filters: dict[str, Any] | None = None,
    ) -> Sequence[RetrievalCandidate]:
        ...


class CandidateReranker(Protocol):
    """
    Cross-encoder/LLM reranker contract.
    """

    async def rerank(
        self,
        query: str,
        candidates: Sequence[RetrievalCandidate],
        *,
        limit: int = 8,
    ) -> Sequence[RetrievalCandidate]:
        ...


# ==========================================================
# METADATA FILTERING
# ==========================================================

class MetadataFilter:
    """
    Lightweight filtering layer.

    Real database/vector implementations should ideally perform
    filtering before returning candidates to reduce work.
    This class provides a final safety/consistency filter.
    """

    @staticmethod
    def matches(
        candidate: RetrievalCandidate,
        filters: dict[str, Any] | None,
    ) -> bool:
        if not filters:
            return True

        metadata = candidate.metadata

        for key, expected in filters.items():
            if expected is None:
                continue

            actual = metadata.get(key)

            # --------------------------------------------------
            # Iterable filter
            # --------------------------------------------------

            if isinstance(
                expected,
                (list, tuple, set, frozenset),
            ):
                if actual not in expected:
                    return False

                continue

            # --------------------------------------------------
            # Boolean filter
            # --------------------------------------------------

            if isinstance(expected, bool):
                if bool(actual) != expected:
                    return False

                continue

            # --------------------------------------------------
            # Simple equality
            # --------------------------------------------------

            if actual != expected:
                return False

        return True

    @classmethod
    def apply(
        cls,
        candidates: Sequence[RetrievalCandidate],
        filters: dict[str, Any] | None,
    ) -> list[RetrievalCandidate]:
        return [
            candidate
            for candidate in candidates
            if cls.matches(candidate, filters)
        ]


# ==========================================================
# RRF FUSION
# ==========================================================

class ReciprocalRankFusion:
    """
    Reciprocal Rank Fusion.

    This is the same hybrid-search concept we used in LegalLens:
    combine independent ranked lists without requiring their raw
    scores to be comparable.

    score = sum(1 / (k + rank))
    """

    @staticmethod
    def fuse(
        ranked_lists: Sequence[
            Sequence[RetrievalCandidate]
        ],
        *,
        k: int = 60,
    ) -> list[RetrievalCandidate]:
        scores: dict[str, float] = {}

        candidates_by_id: dict[
            str,
            RetrievalCandidate,
        ] = {}

        for ranked_list in ranked_lists:
            for index, candidate in enumerate(
                ranked_list,
                start=1,
            ):
                candidates_by_id[
                    candidate.id
                ] = candidate

                scores[candidate.id] = (
                    scores.get(
                        candidate.id,
                        0.0,
                    )
                    + 1.0 / (k + index)
                )

        fused: list[RetrievalCandidate] = []

        for candidate_id, score in scores.items():
            candidate = candidates_by_id[
                candidate_id
            ]

            fused.append(
                RetrievalCandidate(
                    id=candidate.id,
                    text=candidate.text,
                    source_type=candidate.source_type,
                    score=score,
                    metadata={
                        **candidate.metadata,
                        "rrf_score": score,
                    },
                    rank=None,
                )
            )

        fused.sort(
            key=lambda item: item.score,
            reverse=True,
        )

        return fused


# ==========================================================
# SCORE NORMALIZATION
# ==========================================================

class ScoreNormalizer:
    """
    Optional utility for combining native scores.

    RRF remains the primary fusion method because BM25 and vector
    scores are usually not directly comparable.
    """

    @staticmethod
    def min_max(
        candidates: Sequence[RetrievalCandidate],
    ) -> list[RetrievalCandidate]:
        if not candidates:
            return []

        scores = [
            candidate.score
            for candidate in candidates
        ]

        minimum = min(scores)
        maximum = max(scores)

        if minimum == maximum:
            normalized = 1.0

            return [
                RetrievalCandidate(
                    id=candidate.id,
                    text=candidate.text,
                    source_type=candidate.source_type,
                    score=normalized,
                    metadata=candidate.metadata,
                    rank=candidate.rank,
                )
                for candidate in candidates
            ]

        result: list[RetrievalCandidate] = []

        for candidate in candidates:
            score = (
                candidate.score - minimum
            ) / (maximum - minimum)

            result.append(
                RetrievalCandidate(
                    id=candidate.id,
                    text=candidate.text,
                    source_type=candidate.source_type,
                    score=score,
                    metadata=candidate.metadata,
                    rank=candidate.rank,
                )
            )

        return result


# ==========================================================
# FRESHNESS
# ==========================================================

class FreshnessPolicy:
    """
    Determines whether an evidence candidate is fresh enough.

    For the initial layer we use metadata flags rather than making
    assumptions about dates.

    Dynamic/policy agents can enforce stricter rules later.
    """

    @staticmethod
    def is_current(
        candidate: RetrievalCandidate,
    ) -> bool:
        value = candidate.metadata.get(
            "is_current",
        )

        if value is None:
            return True

        return bool(value)

    @classmethod
    def filter_current(
        cls,
        candidates: Sequence[RetrievalCandidate],
    ) -> list[RetrievalCandidate]:
        return [
            candidate
            for candidate in candidates
            if cls.is_current(candidate)
        ]


# ==========================================================
# DEDUPLICATION
# ==========================================================

class CandidateDeduplicator:
    """
    Remove duplicate candidates returned by different retrieval
    strategies or duplicate document chunks.
    """

    @staticmethod
    def deduplicate(
        candidates: Sequence[RetrievalCandidate],
    ) -> list[RetrievalCandidate]:
        seen: set[str] = set()

        result: list[RetrievalCandidate] = []

        for candidate in candidates:
            # Prefer explicit document/chunk identity when available.
            dedupe_key = str(
                candidate.metadata.get(
                    "canonical_id",
                    candidate.id,
                )
            )

            if dedupe_key in seen:
                continue

            seen.add(dedupe_key)
            result.append(candidate)

        return result


# ==========================================================
# EVIDENCE BUILDER
# ==========================================================

class EvidenceBuilder:
    """
    Converts retrieval candidates into application-level evidence
    references.

    The final response layer can use these to show citations/source
    cards without exposing internal retrieval metadata.
    """

    @staticmethod
    def build(
        candidates: Sequence[RetrievalCandidate],
    ) -> tuple[EvidenceRef, ...]:
        evidence: list[EvidenceRef] = []

        for candidate in candidates:
            evidence.append(
                EvidenceRef(
                    evidence_id=candidate.id,

                    title=str(
                        candidate.metadata.get(
                            "title",
                            candidate.id,
                        )
                    ),

                    source_type=candidate.source_type,

                    source_url=(
                        candidate.metadata.get(
                            "source_url",
                        )
                    ),

                    retrieved_at=(
                        candidate.metadata.get(
                            "retrieved_at",
                        )
                    ),

                    verified_at=(
                        candidate.metadata.get(
                            "verified_at",
                        )
                    ),

                    trust_level=str(
                        candidate.metadata.get(
                            "trust_level",
                            "unknown",
                        )
                    ),

                    relevance_score=candidate.score,
                )
            )

        return tuple(evidence)


# ==========================================================
# HYBRID RETRIEVAL RESULT
# ==========================================================

@dataclass(slots=True)
class HybridRetrievalResult:
    """
    Final retrieval output used by the orchestrator/agent layer.
    """

    candidates: tuple[
        RetrievalCandidate,
        ...,
    ]

    evidence: tuple[
        EvidenceRef,
        ...
    ]

    confidence: float = 0.0


# ==========================================================
# HYBRID RETRIEVER
# ==========================================================

class HybridRetriever:
    """
    Hybrid retrieval pipeline.

    Typical flow:

        query
          ↓
        BM25
          +
        Vector Search
          ↓
        RRF
          ↓
        Deduplication
          ↓
        Freshness filtering
          ↓
        Reranker
          ↓
        Top-K
          ↓
        Evidence
    """

    def __init__(
        self,
        *,
        keyword: KeywordRetriever,
        vector: VectorRetriever,
        reranker: CandidateReranker,
    ) -> None:
        self.keyword = keyword

        self.vector = vector

        self.reranker = reranker

    async def retrieve(
        self,
        query: str,
        *,
        plan: RetrievalPlan,
        metadata_filters: dict[str, Any] | None = None,
        candidate_limit: int = 20,
        final_limit: int = 8,
    ) -> HybridRetrievalResult:
        """
        Execute retrieval according to the supplied plan.
        """

        ranked_lists: list[
            Sequence[RetrievalCandidate]
        ] = []

        # ==================================================
        # BM25
        # ==================================================

        if plan.use_bm25:
            keyword_results = (
                await self.keyword.search(
                    query,
                    limit=candidate_limit,
                    filters=metadata_filters,
                )
            )

            keyword_results = (
                MetadataFilter.apply(
                    keyword_results,
                    metadata_filters,
                )
            )

            ranked_lists.append(
                keyword_results
            )

        # ==================================================
        # VECTOR SEARCH
        # ==================================================

        if plan.use_vector:
            vector_results = (
                await self.vector.search(
                    query,
                    limit=candidate_limit,
                    filters=metadata_filters,
                )
            )

            vector_results = (
                MetadataFilter.apply(
                    vector_results,
                    metadata_filters,
                )
            )

            ranked_lists.append(
                vector_results
            )

        # ==================================================
        # FUSION
        # ==================================================

        if ranked_lists:
            fused = ReciprocalRankFusion.fuse(
                ranked_lists,
            )
        else:
            fused = []

        # ==================================================
        # DEDUPLICATION
        # ==================================================

        fused = (
            CandidateDeduplicator.deduplicate(
                fused,
            )
        )

        # ==================================================
        # FRESHNESS
        # ==================================================

        if plan.must_be_fresh:
            fused = FreshnessPolicy.filter_current(
                fused,
            )

        # ==================================================
        # RERANKING
        # ==================================================

        ranked = fused

        if (
            plan.use_reranker
            and fused
        ):
            ranked = (
                await self.reranker.rerank(
                    query,
                    fused,
                    limit=final_limit,
                )
            )

        # ==================================================
        # FINAL LIMIT
        # ==================================================

        ranked = list(
            ranked[:final_limit]
        )

        # ==================================================
        # CONFIDENCE
        # ==================================================

        confidence = (
            self._calculate_confidence(
                ranked,
            )
        )

        # ==================================================
        # EVIDENCE
        # ==================================================

        evidence = (
            EvidenceBuilder.build(
                ranked,
            )
        )

        return HybridRetrievalResult(
            candidates=tuple(ranked),
            evidence=evidence,
            confidence=confidence,
        )

    # ======================================================
    # CONFIDENCE
    # ======================================================

    @staticmethod
    def _calculate_confidence(
        candidates: Sequence[
            RetrievalCandidate
        ],
    ) -> float:
        """
        Simple first-stage confidence.

        Later we can incorporate:
        - reranker score
        - source trust
        - freshness
        - result agreement
        - entity match
        """

        if not candidates:
            return 0.0

        top_score = candidates[0].score

        # RRF scores are normally much smaller than 1.
        # Normalize into a conservative confidence estimate.
        confidence = min(
            max(top_score * 20.0, 0.0),
            1.0,
        )

        # Having multiple independent candidates gives us
        # additional confidence.
        if len(candidates) >= 3:
            confidence = min(
                confidence + 0.10,
                1.0,
            )

        return confidence


# ==========================================================
# CONTEXT BUILDER
# ==========================================================

class RetrievalContextBuilder:
    """
    Build compact evidence context for an agent/LLM.

    We deliberately do not pass the entire metadata object.
    """

    @staticmethod
    def build(
        result: HybridRetrievalResult,
        *,
        max_chars_per_candidate: int = 2000,
    ) -> list[dict[str, Any]]:
        context: list[dict[str, Any]] = []

        for candidate in result.candidates:
            context.append(
                {
                    "evidence_id": candidate.id,

                    "source_type": candidate.source_type,

                    "title": candidate.metadata.get(
                        "title",
                    ),

                    "text": candidate.text[
                        :max_chars_per_candidate
                    ],

                    "source_url": candidate.metadata.get(
                        "source_url",
                    ),

                    "verified_at": candidate.metadata.get(
                        "verified_at",
                    ),

                    "trust_level": candidate.metadata.get(
                        "trust_level",
                    ),

                    "relevance_score": candidate.score,
                }
            )

        return context


# ==========================================================
# PUBLIC EXPORTS
# ==========================================================

__all__ = [
    "RetrievalCandidate",
    "KeywordRetriever",
    "VectorRetriever",
    "CandidateReranker",
    "MetadataFilter",
    "ReciprocalRankFusion",
    "ScoreNormalizer",
    "FreshnessPolicy",
    "CandidateDeduplicator",
    "EvidenceBuilder",
    "HybridRetrievalResult",
    "HybridRetriever",
    "RetrievalContextBuilder",
]
