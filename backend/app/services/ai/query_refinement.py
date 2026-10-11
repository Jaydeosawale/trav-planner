from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Iterable


# ==========================================================
# REFINED QUERY
# ==========================================================

@dataclass(slots=True)
class RefinedQuery:
    """
    Result of query refinement.

    original:
        Exactly what the user typed/spoke.

    normalized:
        Cleaned version.

    rewritten:
        Retrieval/agent-ready version.

    retrieval_queries:
        Multiple semantic/lexical formulations for hybrid retrieval.
    """

    original: str

    normalized: str

    rewritten: str

    retrieval_queries: tuple[str, ...]

    language: str = "en"


# ==========================================================
# NORMALIZER
# ==========================================================

class QueryNormalizer:
    """
    Handles common chat, speech, spelling and abbreviation issues.

    This is intentionally conservative.
    We should not silently change the user's actual intent.
    """

    SPELLING = {
        "japn": "japan",
        "japaan": "japan",
        "maharastra": "maharashtra",
        "maharashtr": "maharashtra",
        "maharashtraa": "maharashtra",
        "banglore": "bangalore",
        "bengaluru": "bengaluru",
        "goa triping": "goa trip",
        "requirments": "requirements",
        "recquirements": "requirements",
        "travell": "travel",
        "travle": "travel",
        "resturent": "restaurant",
        "resturant": "restaurant",
        "resortt": "resort",
        "hotelss": "hotels",
        "beache": "beach",
        "beachs": "beaches",
    }

    ABBREVIATIONS = {
        "pls": "please",
        "plz": "please",
        "u": "you",
        "ur": "your",
        "abt": "about",
        "req": "requirements",
        "reqs": "requirements",
        "info": "information",
        "govt": "government",
        "intl": "international",
        "dom": "domestic",
        "trav": "travel",
        "trvl": "travel",
        "dest": "destination",
        "loc": "location",
        "pref": "preference",
        "prefs": "preferences",
        "frnd": "friend",
        "frnds": "friends",
        "fam": "family",
        "w/": "with",
        "b/w": "between",
        "tmrw": "tomorrow",
        "tdy": "today",
        "wknd": "weekend",
        "mnth": "month",
        "yr": "year",
        "yrs": "years",
        "hr": "hour",
        "hrs": "hours",
        "min": "minutes",
        "mins": "minutes",
        "tym": "time",
        "ppl": "people",
        "prs": "people",
        "2ppl": "2 people",
        "4d": "4 days",
        "5d": "5 days",
        "6d": "6 days",
        "7d": "7 days",
    }

    CHAT_EXPANSIONS = {
        "me n my wife": "my wife and I",
        "me n my husband": "my husband and I",
        "me n my frnds": "my friends and I",
        "me and my frnds": "my friends and I",
        "me n my family": "my family and I",
        "wanna": "want to",
        "gonna": "going to",
        "lemme": "let me",
        "kinda": "kind of",
        "sorta": "sort of",
        "what abt": "what about",
        "how abt": "how about",
        "dont": "do not",
        "doesnt": "does not",
        "cant": "cannot",
        "wont": "will not",
    }

    @classmethod
    def normalize(
        cls,
        text: str,
    ) -> str:
        value = text.strip().lower()

        # --------------------------------------------------
        # Repeated whitespace
        # --------------------------------------------------

        value = re.sub(
            r"\s+",
            " ",
            value,
        )

        # --------------------------------------------------
        # Chat expansions
        # --------------------------------------------------

        for source, target in cls.CHAT_EXPANSIONS.items():
            value = re.sub(
                rf"\b{re.escape(source)}\b",
                target,
                value,
            )

        # --------------------------------------------------
        # Abbreviations
        # --------------------------------------------------

        for source, target in cls.ABBREVIATIONS.items():
            value = re.sub(
                rf"(?<!\w){re.escape(source)}(?!\w)",
                target,
                value,
            )

        # --------------------------------------------------
        # Common spelling mistakes
        # --------------------------------------------------

        for source, target in cls.SPELLING.items():
            value = re.sub(
                rf"\b{re.escape(source)}\b",
                target,
                value,
            )

        # --------------------------------------------------
        # Numeric shorthand
        # --------------------------------------------------

        value = re.sub(
            r"\b(\d+)\s*d\b",
            r"\1 days",
            value,
        )

        value = re.sub(
            r"\b(\d+)\s*n\b",
            r"\1 nights",
            value,
        )

        # --------------------------------------------------
        # Currency shorthand
        # --------------------------------------------------

        value = value.replace(
            "rs.",
            "inr ",
        )

        value = value.replace(
            "rs ",
            "inr ",
        )

        # --------------------------------------------------
        # Clean punctuation
        # --------------------------------------------------

        value = re.sub(
            r"\s+([?!.,])",
            r"\1",
            value,
        )

        value = re.sub(
            r"\?+",
            "?",
            value,
        )

        return value.strip()[:10000]


# ==========================================================
# CONVERSATION RESOLVER
# ==========================================================

class ConversationResolver:
    """
    Resolves references such as:

        "best beaches?"

    after:

        "Tell me about Goa."

    This is done using application-side conversation state.
    """

    REFERENCE_PATTERNS = (
        "it",
        "there",
        "that place",
        "that city",
        "that country",
        "this place",
        "this city",
        "this country",
        "there",
        "what about",
        "how about",
        "also",
        "and hotels",
        "and restaurants",
    )

    @classmethod
    def resolve(
        cls,
        query: str,
        *,
        recent_turns: Iterable[dict[str, str]] = (),
        current_destination: str | None = None,
    ) -> str:
        normalized = query.strip()

        # No context required.
        if not recent_turns and not current_destination:
            return normalized

        context_destination = (
            current_destination
            or cls._find_recent_destination(
                recent_turns,
            )
        )

        if not context_destination:
            return normalized

        lower = normalized.lower()

        # --------------------------------------------------
        # "best beaches?"
        # --------------------------------------------------

        context_reference_phrases = (
            "best beaches",
            "best places",
            "best hotels",
            "best restaurants",
            "restaurants",
            "hotels",
            "cafes",
            "places",
            "things to do",
            "what about",
            "how about",
        )

        if any(
            phrase in lower
            for phrase in context_reference_phrases
        ):
            if context_destination.lower() not in lower:
                return (
                    f"{normalized} in "
                    f"{context_destination}"
                )

        # --------------------------------------------------
        # "there"
        # --------------------------------------------------

        if re.search(
            r"\bthere\b",
            lower,
        ):
            return re.sub(
                r"\bthere\b",
                context_destination,
                normalized,
                flags=re.IGNORECASE,
            )

        return normalized

    @staticmethod
    def _find_recent_destination(
        recent_turns: Iterable[dict[str, str]],
    ) -> str | None:
        known_destinations = (
            "goa",
            "mumbai",
            "delhi",
            "japan",
            "kerala",
            "kashmir",
            "manali",
            "bali",
            "thailand",
            "singapore",
            "paris",
        )

        turns = list(recent_turns)

        # Newest messages first.
        turns.reverse()

        for turn in turns:
            content = str(
                turn.get(
                    "content",
                    "",
                )
            ).lower()

            for destination in known_destinations:
                if destination in content:
                    return destination.title()

        return None


# ==========================================================
# QUERY REWRITER
# ==========================================================

class QueryRewriter:
    """
    Converts normalized natural language into a clean retrieval query.

    This is deliberately conservative in Phase 1.
    A structured LLM rewriter can later improve difficult queries.
    """

    @staticmethod
    def rewrite(
        normalized: str,
    ) -> str:
        query = normalized.strip()

        # --------------------------------------------------
        # Remove filler language
        # --------------------------------------------------

        filler_patterns = (
            r"\bi want to know\b",
            r"\bcan you tell me\b",
            r"\bcould you tell me\b",
            r"\bplease tell me\b",
            r"\bplease\b",
            r"\bi want\b",
            r"\bcan you\b",
            r"\bcould you\b",
        )

        for pattern in filler_patterns:
            query = re.sub(
                pattern,
                "",
                query,
                flags=re.IGNORECASE,
            )

        query = re.sub(
            r"\s+",
            " ",
            query,
        ).strip()

        return query


# ==========================================================
# MULTI-QUERY GENERATOR
# ==========================================================

class MultiQueryGenerator:
    """
    Generate a small set of retrieval formulations.

    We keep this deterministic initially.

    Later we can add a cheap structured-output LLM call,
    but must enforce a maximum query count.
    """

    @staticmethod
    def generate(
        rewritten_query: str,
    ) -> tuple[str, ...]:
        query = rewritten_query.strip()

        if not query:
            return ()

        queries: list[str] = [
            query,
        ]

        lower = query.lower()

        # --------------------------------------------------
        # Visa / policy
        # --------------------------------------------------

        if "visa" in lower:
            queries.extend(
                [
                    f"{query} visa requirements",
                    f"{query} tourist entry requirements",
                    f"{query} official immigration requirements",
                ]
            )

        # --------------------------------------------------
        # Places
        # --------------------------------------------------

        if (
            "place" in lower
            or "places" in lower
            or "visit" in lower
            or "attraction" in lower
        ):
            queries.extend(
                [
                    f"{query} tourist attractions",
                    f"{query} things to do",
                    f"{query} popular places",
                ]
            )

        # --------------------------------------------------
        # Hotels
        # --------------------------------------------------

        if "hotel" in lower:
            queries.extend(
                [
                    f"{query} accommodation",
                    f"{query} hotels to stay",
                ]
            )

        # --------------------------------------------------
        # Restaurants / food
        # --------------------------------------------------

        if (
            "restaurant" in lower
            or "restaurants" in lower
            or "cafe" in lower
            or "food" in lower
        ):
            queries.extend(
                [
                    f"{query} restaurants",
                    f"{query} local food",
                    f"{query} cafes",
                ]
            )

        # --------------------------------------------------
        # Remove duplicates
        # --------------------------------------------------

        unique: list[str] = []

        for item in queries:
            clean = re.sub(
                r"\s+",
                " ",
                item,
            ).strip()

            if clean and clean not in unique:
                unique.append(clean)

        # Keep retrieval cost bounded.
        return tuple(
            unique[:5]
        )


# ==========================================================
# COMPLETE REFINEMENT
# ==========================================================

class QueryRefinementService:
    """
    One entry point for complete query refinement.
    """

    @classmethod
    def refine(
        cls,
        text: str,
        *,
        recent_turns: Iterable[dict[str, str]] = (),
        current_destination: str | None = None,
    ) -> RefinedQuery:
        original = text

        normalized = QueryNormalizer.normalize(
            text,
        )

        contextual = ConversationResolver.resolve(
            normalized,
            recent_turns=recent_turns,
            current_destination=current_destination,
        )

        rewritten = QueryRewriter.rewrite(
            contextual,
        )

        retrieval_queries = (
            MultiQueryGenerator.generate(
                rewritten,
            )
        )

        return RefinedQuery(
            original=original,
            normalized=normalized,
            rewritten=rewritten,
            retrieval_queries=retrieval_queries,
            language="en",
        )


__all__ = [
    "RefinedQuery",
    "QueryNormalizer",
    "ConversationResolver",
    "QueryRewriter",
    "MultiQueryGenerator",
    "QueryRefinementService",
]
