"""
Destination and place discovery layer.

This package combines:
- Trav Planner PostgreSQL/CMS data
- RAG/vector knowledge
- Google Places
- OpenStreetMap
- personalization/context

into normalized, deduplicated and ranked candidates.
"""

from .destination_discovery import DestinationDiscoveryService
from .entity_resolver import EntityResolver
from .source_merger import DiscoverySourceMerger
from .candidate_ranker import (
    DiscoveryCandidateRanker,
    DiscoveryRankingContext,
    RankedDiscoveryCandidate,
)

__all__ = [
    "DestinationDiscoveryService",
    "EntityResolver",
    "DiscoverySourceMerger",
    "DiscoveryCandidateRanker",
    "DiscoveryRankingContext",
    "RankedDiscoveryCandidate",
]
