from __future__ import annotations

import re

from .contracts import (
    Intent,
    QueryEntities,
    QueryState,
)

from .query_refinement import (
    QueryRefinementService,
)

from .query_models import (
    ActionLevel,
    ConstraintType,
    EntityType,
    QueryAmbiguity,
    QueryConfidence,
    QueryEntity,
    QueryTask,
    RetrievalPlan,
    TravelConstraint,
    TravelDateRange,
    TravelQuery,
 )
from .date_resolver import DateTimeResolver

class QueryUnderstanding:
    """
    Structured understanding layer.

    Existing pipeline:

        User Query
            ↓
        QueryRefinementService
            ↓
        normalized / rewritten query
            ↓
        intent detection
            ↓
        entity extraction
            ↓
        requirement analysis
            ↓
        QueryState

    New pipeline:

        QueryState
            ↓
        TravelQuery

    TravelQuery is the new canonical contract that will eventually
    become the main contract between:

        input processing
            ↓
        query understanding
            ↓
        context
            ↓
        retrieval planning
            ↓
        retrieval
            ↓
        agents
            ↓
        response generation
    """

    # ==========================================================
    # INTENT PATTERNS
    # ==========================================================

    INTENT_PATTERNS: tuple[
        tuple[str, Intent],
        ...,
    ] = (
        # ------------------------------------------------------
        # Policy / regulated information
        # ------------------------------------------------------

        ("visa", Intent.VISA_POLICY),

        ("immigration", Intent.TRAVEL_POLICY),

        ("entry requirement", Intent.TRAVEL_POLICY),

        ("entry requirements", Intent.TRAVEL_POLICY),

        ("travel advisory", Intent.TRAVEL_POLICY),

        ("travel warning", Intent.TRAVEL_POLICY),

        ("passport requirement", Intent.TRAVEL_POLICY),

        # ------------------------------------------------------
        # Weather
        # ------------------------------------------------------

        ("weather", Intent.WEATHER),

        ("rain", Intent.WEATHER),

        ("temperature", Intent.WEATHER),

        ("forecast", Intent.WEATHER),

        # ------------------------------------------------------
        # Routing
        # ------------------------------------------------------

        ("how far", Intent.ROUTE_PLANNING),

        ("distance", Intent.ROUTE_PLANNING),

        ("travel time", Intent.ROUTE_PLANNING),

        ("route", Intent.ROUTE_PLANNING),

        ("directions", Intent.ROUTE_PLANNING),

        # ------------------------------------------------------
        # Booking / actions
        # ------------------------------------------------------

        ("book", Intent.BOOKING_ACTION),

        ("reserve", Intent.BOOKING_ACTION),

        ("payment", Intent.BOOKING_ACTION),

        ("pay for", Intent.BOOKING_ACTION),

        ("confirm booking", Intent.BOOKING_ACTION),

        # ------------------------------------------------------
        # Transport discovery
        # ------------------------------------------------------

        ("airport", Intent.AIRPORT_SEARCH),

        ("airports", Intent.AIRPORT_SEARCH),

        ("railway station", Intent.RAILWAY_SEARCH),

        ("train station", Intent.RAILWAY_SEARCH),

        ("flight", Intent.FLIGHT_SEARCH),

        ("flights", Intent.FLIGHT_SEARCH),

        ("train", Intent.TRAIN_SEARCH),

        ("trains", Intent.TRAIN_SEARCH),

        # ------------------------------------------------------
        # Accommodation
        # ------------------------------------------------------

        ("hotel", Intent.HOTEL_SEARCH),

        ("hotels", Intent.HOTEL_SEARCH),

        ("resort", Intent.HOTEL_SEARCH),

        ("resorts", Intent.HOTEL_SEARCH),

        ("stay", Intent.HOTEL_SEARCH),

        ("accommodation", Intent.HOTEL_SEARCH),

        # ------------------------------------------------------
        # Food
        # ------------------------------------------------------

        ("restaurant", Intent.RESTAURANT_SEARCH),

        ("restaurants", Intent.RESTAURANT_SEARCH),

        ("cafe", Intent.RESTAURANT_SEARCH),

        ("cafes", Intent.RESTAURANT_SEARCH),

        ("food", Intent.RESTAURANT_SEARCH),

        ("eat", Intent.RESTAURANT_SEARCH),

        # ------------------------------------------------------
        # Itinerary
        # ------------------------------------------------------

        ("itinerary", Intent.ITINERARY_GENERATION),

        ("day wise", Intent.ITINERARY_GENERATION),

        ("day-wise", Intent.ITINERARY_GENERATION),

        # ------------------------------------------------------
        # Trip planning
        # ------------------------------------------------------

        ("plan a trip", Intent.TRIP_PLANNING),

        ("plan trip", Intent.TRIP_PLANNING),

        ("plan my trip", Intent.TRIP_PLANNING),

        ("plan for me", Intent.TRIP_PLANNING),

        ("trip plan", Intent.TRIP_PLANNING),

        ("trip", Intent.TRIP_PLANNING),

        # ------------------------------------------------------
        # Destination discovery
        # ------------------------------------------------------

        ("best places", Intent.DESTINATION_DISCOVERY),

        ("places to visit", Intent.DESTINATION_DISCOVERY),

        ("things to do", Intent.DESTINATION_DISCOVERY),

        ("what to see", Intent.DESTINATION_DISCOVERY),

        ("tourist places", Intent.DESTINATION_DISCOVERY),

        ("attractions", Intent.PLACE_SEARCH),

        ("places", Intent.PLACE_SEARCH),

        ("place", Intent.PLACE_SEARCH),
    )

    # ==========================================================
    # DESTINATIONS
    # ==========================================================

    KNOWN_DESTINATIONS = (
        "goa",
        "mumbai",
        "delhi",
        "pune",
        "jaipur",
        "udaipur",
        "jodhpur",
        "kerala",
        "kashmir",
        "manali",
        "shimla",
        "agra",
        "varanasi",
        "hyderabad",
        "bangalore",
        "bengaluru",
        "chennai",
        "kolkata",
        "maharashtra",
        "rajasthan",
        "japan",
        "bali",
        "thailand",
        "singapore",
        "malaysia",
        "sri lanka",
        "dubai",
        "paris",
        "london",
        "italy",
        "switzerland",
    )

    # ==========================================================
    # INTENT DETECTION
    # ==========================================================

    @classmethod
    def detect_intent(
        cls,
        normalized_query: str,
    ) -> Intent:
        """
        Determine the PRIMARY intent.

        A request such as:

            "mala Goa la 3 divas trip plan karaychi aahe,
             cheap hotel ani beaches pahijet"

        is primarily:

            TRIP_PLANNING

        while hotel/beach/cafe become sub-intents.
        """

        query = normalized_query.lower()

        # ------------------------------------------------------
        # Booking / consequential action
        # ------------------------------------------------------

        booking_patterns = (
            "book ",
            "reserve ",
            "reservation",
            "make a booking",
            "confirm booking",
            "make payment",
            "pay for",
            "बुक",
        )

        if any(
            phrase in query
            for phrase in booking_patterns
        ):
            return Intent.BOOKING_ACTION

        # ------------------------------------------------------
        # Policy
        # ------------------------------------------------------
        # Policy must be checked before generic "visit/travel"
        # patterns. Example:
        #   "Do I need a visa to visit Goa?"
        # is a policy request, not trip planning.

        policy_patterns = (
            "visa",
            "immigration",
            "entry requirement",
            "entry requirements",
            "passport requirement",
            "passport requirements",
            "travel advisory",
            "travel warning",
        )

        if any(
            phrase in query
            for phrase in policy_patterns
        ):
            return Intent.TRAVEL_POLICY

        # ------------------------------------------------------
        # Explicit trip planning
        # ------------------------------------------------------

        planning_patterns = (
            "plan a trip",
            "plan trip",
            "plan my trip",
            "plan for me",
            "trip plan",
            "trip planning",
            "itinerary",
            "day wise",
            "day-wise",
            "tour plan",
            "trip",

            # Marathi transliteration
            "trip plan kar",
            "trip plan karaychi",
            "trip plan karaycha",
            "trip planning karaychi",
            "jaych aahe",
            "jaycha aahe",
            "jaychi aahe",
            "phiraych aahe",
            "firaych aahe",
            "bhet dyaychi",

            # Hindi transliteration
            "ghumna hai",
            "ghumne jana",
            "trip banana",
            "trip plan karna",
            "jana hai",
        )

        if any(
            phrase in query
            for phrase in planning_patterns
        ):
            return Intent.TRIP_PLANNING

        # ------------------------------------------------------
        # Devanagari Marathi travel request
        # ------------------------------------------------------

        marathi_travel_patterns = (
            "जायचं",
            "जायचे",
            "जायची",
            "जायचा",
            "जायचं आहे",
            "जायचे आहे",
            "जायची आहे",
            "जायचा आहे",
            "फिरायला",
            "फिरायचं",
            "भेट द्यायची",
            "सहल",
            "प्रवास",
            "प्रवासाला",
        )

        if any(
            phrase in query
            for phrase in marathi_travel_patterns
        ):
            return Intent.TRIP_PLANNING

        # ------------------------------------------------------
        # English visit/travel request
        # ------------------------------------------------------

        english_travel_patterns = (
            "want to visit",
            "to visit",
            "want to travel",
            "to travel",
            "want to go",
            "to go",
            "going to",
            "travelling to",
            "traveling to",
            "planning to visit",
            "planning a trip",
            "visit ",
            "travel to",
        )

        if any(
            phrase in query
            for phrase in english_travel_patterns
        ):
            return Intent.TRIP_PLANNING

        # ------------------------------------------------------
        # Weather
        # ------------------------------------------------------

        weather_patterns = (
            "weather",
            "forecast",
            "temperature",
            "rain",
        )

        if any(
            phrase in query
            for phrase in weather_patterns
        ):
            return Intent.WEATHER

        # ------------------------------------------------------
        # Route
        # ------------------------------------------------------

        route_patterns = (
            "how far",
            "distance",
            "travel time",
            "directions",
            "route",
            "from ",
        )

        if any(
            phrase in query
            for phrase in route_patterns
        ):
            return Intent.ROUTE_PLANNING

        # ------------------------------------------------------
        # Hotel
        # ------------------------------------------------------

        if any(
            phrase in query
            for phrase in (
                "hotel",
                "hotels",
                "resort",
                "resorts",
                "accommodation",
                "where to stay",
            )
        ):
            return Intent.HOTEL_SEARCH

        # ------------------------------------------------------
        # Food
        # ------------------------------------------------------

        if any(
            phrase in query
            for phrase in (
                "restaurant",
                "restaurants",
                "cafe",
                "cafes",
                "food",
                "where to eat",
            )
        ):
            return Intent.RESTAURANT_SEARCH

        # ------------------------------------------------------
        # Flights
        # ------------------------------------------------------

        if any(
            phrase in query
            for phrase in (
                "flight",
                "flights",
            )
        ):
            return Intent.FLIGHT_SEARCH

        # ------------------------------------------------------
        # Trains
        # ------------------------------------------------------

        if any(
            phrase in query
            for phrase in (
                "train",
                "trains",
                "railway",
            )
        ):
            return Intent.TRAIN_SEARCH

        # ------------------------------------------------------
        # Discovery
        # ------------------------------------------------------

        if any(
            phrase in query
            for phrase in (
                "best places",
                "places to visit",
                "things to do",
                "what to see",
                "tourist places",
                "attractions",
            )
        ):
            return Intent.DESTINATION_DISCOVERY

        return Intent.GENERAL_CHAT


    @classmethod
    def detect_sub_intents(
        cls,
        normalized_query: str,
        primary_intent: Intent,
    ) -> tuple[str, ...]:
        """
        Detect secondary tasks contained in the same request.

        Example:

            "Goa trip with cheap hotels, beaches and cafes"

        returns:

            hotel_search
            beach_discovery
            cafe_discovery
        """

        query = normalized_query.lower()

        found: list[str] = []

        def add(value: str) -> None:
            if value not in found:
                found.append(value)

        # ------------------------------------------------------
        # Accommodation
        # ------------------------------------------------------

        if any(
            word in query
            for word in (
                "hotel",
                "hotels",
                "resort",
                "resorts",
                "accommodation",
                "stay",
                "where to stay",
            )
        ):
            add("hotel_search")

        # ------------------------------------------------------
        # Beaches
        # ------------------------------------------------------

        if any(
            word in query
            for word in (
                "beach",
                "beaches",
            )
        ):
            add("beach_discovery")

        # ------------------------------------------------------
        # Cafes
        # ------------------------------------------------------

        if any(
            word in query
            for word in (
                "cafe",
                "cafes",
                "coffee",
            )
        ):
            add("cafe_discovery")

        # ------------------------------------------------------
        # Restaurants
        # ------------------------------------------------------

        if any(
            word in query
            for word in (
                "restaurant",
                "restaurants",
                "food",
                "where to eat",
            )
        ):
            add("restaurant_search")

        # ------------------------------------------------------
        # Nature
        # ------------------------------------------------------

        if any(
            word in query
            for word in (
                "nature",
                "natural places",
                "waterfall",
                "waterfalls",
                "forest",
                "wildlife",
            )
        ):
            add("nature_discovery")

        # ------------------------------------------------------
        # Activities
        # ------------------------------------------------------

        if any(
            word in query
            for word in (
                "activity",
                "activities",
                "things to do",
                "adventure",
                "trekking",
                "hiking",
            )
        ):
            add("activity_discovery")

        # ------------------------------------------------------
        # Maps
        # ------------------------------------------------------

        if any(
            word in query
            for word in (
                "near",
                "nearby",
                "distance",
                "route",
                "how far",
            )
        ):
            add("geospatial_search")

        return tuple(found)




    # ==========================================================
    # DESTINATION EXTRACTION
    # ==========================================================

    @classmethod
    def extract_destination(
        cls,
        query: str,
    ) -> str | None:

        lower = query.lower()

        # ------------------------------------------------------
        # Canonical aliases
        # ------------------------------------------------------

        aliases = {
            "गोवा": "Goa",
            "गोव्याला": "Goa",
            "मुंबई": "Mumbai",
            "मुंबईला": "Mumbai",
            "पुणे": "Pune",
            "पुण्याला": "Pune",
            "दिल्ली": "Delhi",
            "दिल्लीला": "Delhi",
            "जयपूर": "Jaipur",
            "उदयपूर": "Udaipur",
            "काश्मीर": "Kashmir",
            "मनाली": "Manali",
            "केरळ": "Kerala",
        }

        for alias, canonical in aliases.items():

            if alias in query:
                return canonical

        # ------------------------------------------------------
        # Existing Latin destination matching
        # ------------------------------------------------------

        destinations = sorted(
            cls.KNOWN_DESTINATIONS,
            key=len,
            reverse=True,
        )

        for destination in destinations:

            if destination in lower:

                if destination == "bengaluru":
                    return "Bengaluru"

                if destination == "sri lanka":
                    return "Sri Lanka"

                return destination.title()

        return None
    # ==========================================================
    # ORIGIN EXTRACTION
    # ==========================================================

    @staticmethod
    def extract_origin(
        query: str,
    ) -> str | None:
        """
        Basic extraction for:

            from Pune to Goa
            Mumbai to Goa
            travelling from Delhi

        Multilingual/transliterated origin extraction will be
        added in the next Query Intelligence iteration.
        """

        match = re.search(
            r"\bfrom\s+([A-Za-z][A-Za-z ]{1,60})\s+to\b",
            query,
            flags=re.IGNORECASE,
        )

        if match:
            return match.group(1).strip().title()

        return None

    # ==========================================================
    # DURATION
    # ==========================================================

    @staticmethod
    def extract_duration(
        query: str,
    ) -> int | None:
        value = query.lower()

        patterns = (
            # 3 days
            r"\b(\d+)\s*(?:day|days)\b",

            # 3d
            r"\b(\d+)\s*d\b",

            # 3 nights / 3 night
            r"\b(\d+)\s*nights?\b",

            # 3 divas - Marathi transliteration
            r"\b(\d+)\s*divas\b",

            # 3 दिवस
            r"(\d+)\s*दिवस",
        )

        for pattern in patterns:

            match = re.search(
                pattern,
                value,
            )

            if not match:
                continue

            try:
                days = int(match.group(1))
            except ValueError:
                continue

            if 1 <= days <= 365:
                return days

        # ------------------------------------------------------
        # 2n3d / 2n 3d
        # ------------------------------------------------------

        match = re.search(
            r"\b(\d+)\s*n\s*(\d+)\s*d\b",
            value,
        )

        if match:

            try:
                days = int(match.group(2))
            except ValueError:
                return None

            if 1 <= days <= 365:
                return days

        return None



    # ==========================================================
    # TRAVELERS
    # ==========================================================

    @staticmethod
    def extract_traveler_count(
        query: str,
    ) -> int | None:
        patterns = (
            r"\bfor\s+(\d+)\s*"
            r"(?:people|person|traveler|travelers|"
            r"traveller|travellers|adults|persons)\b",

            r"\bwith\s+(\d+)\s*"
            r"(?:people|person|traveler|travelers|"
            r"traveller|travellers|adults|persons)\b",

            r"\b(\d+)\s*(?:people|person|travelers?|travellers?|adults?)\b",

            # Hindi/Marathi transliteration
            r"\b(\d+)\s*(?:log|jan|janas?)\b",
        )

        for pattern in patterns:

            match = re.search(
                pattern,
                query.lower(),
            )

            if not match:
                continue

            try:
                count = int(match.group(1))
            except ValueError:
                return None

            if 1 <= count <= 100:
                return count

        return None

    # ==========================================================
    # BUDGET
    # ==========================================================

    @staticmethod
    def extract_budget(
        query: str,
    ) -> tuple[float | None, str | None]:
        """
        Supports basic forms:

            ₹30000
            Rs 30000
            30000 INR
            $1000
            50k
            1.5 lakh
        """

        value = query.lower()

        # ------------------------------------------------------
        # Explicit currencies
        # ------------------------------------------------------

        patterns = (
            (
                r"₹\s*([0-9]+(?:\.[0-9]+)?)",
                "INR",
            ),
            (
                r"\b([0-9]+(?:\.[0-9]+)?)\s*"
                r"(?:inr|rs|rupees)\b",
                "INR",
            ),
            (
                r"\$\s*([0-9]+(?:\.[0-9]+)?)",
                "USD",
            ),
            (
                r"\b([0-9]+(?:\.[0-9]+)?)\s*"
                r"(?:usd|dollars?)\b",
                "USD",
            ),
        )

        for pattern, currency in patterns:

            match = re.search(
                pattern,
                value,
            )

            if match:
                try:
                    return (
                        float(match.group(1)),
                        currency,
                    )
                except ValueError:
                    return None, None

        # ------------------------------------------------------
        # 30k
        # ------------------------------------------------------

        match = re.search(
            r"\b([0-9]+(?:\.[0-9]+)?)\s*k\b",
            value,
        )

        if match:
            try:
                return (
                    float(match.group(1)) * 1000,
                    "INR",
                )
            except ValueError:
                return None, None

        # ------------------------------------------------------
        # 1.5 lakh
        # ------------------------------------------------------

        match = re.search(
            r"\b([0-9]+(?:\.[0-9]+)?)\s*lakh\b",
            value,
        )

        if match:
            try:
                return (
                    float(match.group(1)) * 100000,
                    "INR",
                )
            except ValueError:
                return None, None

        return None, None

    # ==========================================================
    # BUDGET LEVEL
    # ==========================================================
    @staticmethod
    def extract_budget_level(
        query: str,
    ) -> str | None:

        value = query.lower()

        if any(
            phrase in value
            for phrase in (
                "cheap",
                "budget",
                "low cost",
                "low-cost",
                "affordable",
                "economical",
                "cheap",
                "low budget",
                "low-budget",
                "swast",
                "swasta",
                "parvadnare",
                "parvadnara",
                "kam budget",
                "sasta",
                "स्वस्त",
                "परवडणारे",
            )
        ):
            return "budget"

        if any(
            phrase in value
            for phrase in (
                "luxury",
                "luxurious",
                "premium",
                "5 star",
                "5-star",
            )
        ):
            return "luxury"

        if any(
            phrase in value
            for phrase in (
                "mid range",
                "mid-range",
                "moderate",
            )
        ):
            return "mid_range"

        return None



    # ==========================================================
    # LANGUAGE DETECTION
    # ==========================================================

    @staticmethod
    def detect_query_language(
        query: str,
    ) -> tuple[str | None, tuple[str, ...], str | None]:
        """
        Lightweight language/script detection.

        Important:
        - Raw query is preserved.
        - Latin transliteration is supported heuristically.
        - Latin-language detection uses token boundaries to
          avoid false positives such as "ke" inside "weekend".
        """

        value = query.strip()

        if not value:
            return None, (), None

        lowered = value.lower()

        # ------------------------------------------------------
        # Script detection
        # ------------------------------------------------------

        devanagari_count = sum(
            1
            for char in value
            if "\u0900" <= char <= "\u097F"
        )

        latin_count = sum(
            1
            for char in value
            if char.isascii() and char.isalpha()
        )

        if (
            devanagari_count > 0
            and latin_count > 0
        ):
            script = "mixed"

        elif devanagari_count > 0:
            script = "devanagari"

        else:
            script = "latin"

        # ------------------------------------------------------
        # Tokenization for Latin script
        # ------------------------------------------------------

        tokens = set(
            re.findall(
                r"[a-zA-Z]+",
                lowered,
            )
        )

        # ------------------------------------------------------
        # Marathi transliteration vocabulary
        # ------------------------------------------------------

        marathi_terms = {
            "mala",
            "majha",
            "majhi",
            "majhe",
            "ahe",
            "aahe",
            "jaych",
            "jaycha",
            "jaychi",
            "pahije",
            "pahije",
            "kiti",
            "kuthe",
            "kasa",
            "kashi",
            "kay",
            "aani",
            "ani",
            "madhe",
            "sathi",
            "sobat",
            "divas",
            "divasa",
            "pudhchya",
            "swast",
            "parvadnare",
        }

        # ------------------------------------------------------
        # Hindi transliteration vocabulary
        # ------------------------------------------------------

        hindi_terms = {
            "mujhe",
            "mera",
            "meri",
            "mere",
            "hai",
            "hain",
            "jana",
            "jaana",
            "chahiye",
            "kitne",
            "kahan",
            "kaise",
            "aur",
            "liye",
            "saath",
            "din",
        }

        # ------------------------------------------------------
        # Devanagari language indicators
        # ------------------------------------------------------

        marathi_devanagari_terms = (
            "मला",
            "माझा",
            "माझी",
            "माझे",
            "आहे",
            "जायचं",
            "जायचे",
            "पाहिजे",
            "कुठे",
            "किती",
            "दिवस",
            "पुढच्या",
            "स्वस्त",
        )

        hindi_devanagari_terms = (
            "मुझे",
            "मेरा",
            "मेरी",
            "मेरे",
            "है",
            "हैं",
            "जाना",
            "चाहिए",
            "कितने",
            "कहाँ",
            "कैसे",
            "दिन",
        )

        # ------------------------------------------------------
        # Count language evidence
        # ------------------------------------------------------

        marathi_hits = sum(
            1
            for term in marathi_terms
            if term in tokens
        )

        hindi_hits = sum(
            1
            for term in hindi_terms
            if term in tokens
        )

        marathi_dev_hits = sum(
            1
            for term in marathi_devanagari_terms
            if term in value
        )

        hindi_dev_hits = sum(
            1
            for term in hindi_devanagari_terms
            if term in value
        )

        marathi_hits += marathi_dev_hits
        hindi_hits += hindi_dev_hits

        # ------------------------------------------------------
        # English vocabulary
        # ------------------------------------------------------

        english_terms = {
            "the",
            "trip",
            "travel",
            "hotel",
            "hotels",
            "beach",
            "beaches",
            "cafe",
            "cafes",
            "restaurant",
            "restaurants",
            "cheap",
            "budget",
            "next",
            "weekend",
            "days",
            "day",
            "from",
            "to",
            "near",
            "best",
            "places",
            "visit",
            "want",
            "plan",
            "planning",
        }

        english_hits = sum(
            1
            for term in english_terms
            if term in tokens
        )

        # ------------------------------------------------------
        # Devanagari-only query
        # ------------------------------------------------------

        if (
            devanagari_count > 0
            and latin_count == 0
        ):

            if marathi_hits > hindi_hits:
                return (
                    "mr",
                    ("mr",),
                    "devanagari",
                )

            if hindi_hits > marathi_hits:
                return (
                    "hi",
                    ("hi",),
                    "devanagari",
                )

        # ------------------------------------------------------
        # Mixed Marathi + English
        # ------------------------------------------------------

        if (
            marathi_hits > 0
            and english_hits > 0
        ):
            return (
                "mr",
                ("mr", "en"),
                script,
            )

        # ------------------------------------------------------
        # Mixed Hindi + English
        # ------------------------------------------------------

        if (
            hindi_hits > 0
            and english_hits > 0
        ):
            return (
                "hi",
                ("hi", "en"),
                script,
            )

        # ------------------------------------------------------
        # Marathi
        # ------------------------------------------------------

        if marathi_hits > 0:
            return (
                "mr",
                ("mr",),
                script,
            )

        # ------------------------------------------------------
        # Hindi
        # ------------------------------------------------------

        if hindi_hits > 0:
            return (
                "hi",
                ("hi",),
                script,
            )

        # ------------------------------------------------------
        # English
        # ------------------------------------------------------

        if english_hits > 0:
            return (
                "en",
                ("en",),
                script,
            )

        # ------------------------------------------------------
        # Safe fallback
        # ------------------------------------------------------

        return (
            "en",
            ("en",),
            script,
        )
    # ==========================================================
    # NATIONALITY
    # ==========================================================

    @staticmethod
    def extract_nationality(
        query: str,
    ) -> str | None:

        value = query.lower()

        known = (
            ("indian", "Indian"),
            ("india", "Indian"),
            ("american", "American"),
            ("usa", "American"),
            ("british", "British"),
            ("uk", "British"),
            ("canadian", "Canadian"),
            ("canada", "Canadian"),
            ("australian", "Australian"),
            ("australia", "Australian"),
        )

        for phrase, nationality in known:

            if phrase in value:
                return nationality

        return None

    # ==========================================================
    # INTERESTS
    # ==========================================================

    @staticmethod
    def extract_interests(
        query: str,
    ) -> tuple[str, ...]:

        value = query.lower()

        canonical_interests = {
            "beach": (
                "beach",
                "beaches",
            ),
            "cafe": (
                "cafe",
                "cafes",
                "coffee",
            ),
            "restaurant": (
                "restaurant",
                "restaurants",
                "food",
            ),
            "mountain": (
                "mountain",
                "mountains",
            ),
            "hiking": (
                "hiking",
                "trekking",
            ),
            "shopping": (
                "shopping",
            ),
            "history": (
                "history",
                "historical",
            ),
            "culture": (
                "culture",
            ),
            "temple": (
                "temple",
                "temples",
            ),
            "wildlife": (
                "wildlife",
            ),
            "nightlife": (
                "nightlife",
            ),
            "adventure": (
                "adventure",
            ),
            "nature": (
                "nature",
                "natural places",
            ),
            "photography": (
                "photography",
            ),
            "relaxation": (
                "relaxation",
                "relaxed",
                "peaceful",
            ),
        }

        found: list[str] = []

        for canonical, variants in (
            canonical_interests.items()
        ):

            if any(
                variant in value
                for variant in variants
            ):
                found.append(canonical)

        return tuple(found)
    
    # ==========================================================
    # PLACE TYPE
    # ==========================================================

    @staticmethod
    def place_type_for_intent(
        intent: Intent,
    ) -> str | None:

        mapping = {
            Intent.HOTEL_SEARCH: "hotel",
            Intent.RESTAURANT_SEARCH: "restaurant",
            Intent.AIRPORT_SEARCH: "airport",
            Intent.RAILWAY_SEARCH: "railway_station",
            Intent.FLIGHT_SEARCH: "flight",
            Intent.TRAIN_SEARCH: "train",
        }

        return mapping.get(intent)

    # ==========================================================
    # MISSING SLOTS
    # ==========================================================

    @classmethod
    def calculate_missing_slots(
        cls,
        *,
        intent: Intent,
        entities: QueryEntities,
    ) -> tuple[str, ...]:

        missing: list[str] = []

        # ------------------------------------------------------
        # Trip planning
        # ------------------------------------------------------

        if intent in {
            Intent.TRIP_PLANNING,
            Intent.ITINERARY_GENERATION,
        }:

            if not entities.destination:
                missing.append(
                    "destination"
                )

            elif not entities.duration_days:
                missing.append(
                    "duration_days"
                )

            return tuple(
                missing
            )

        # ------------------------------------------------------
        # Routing
        # ------------------------------------------------------

        if intent == Intent.ROUTE_PLANNING:

            if not entities.origin:
                missing.append(
                    "origin"
                )

            if not entities.destination:
                missing.append(
                    "destination"
                )

            return tuple(
                missing
            )

        # ------------------------------------------------------
        # Policy
        # ------------------------------------------------------

        if intent in {
            Intent.VISA_POLICY,
            Intent.TRAVEL_POLICY,
        }:

            if not entities.destination:
                missing.append(
                    "destination"
                )

            if not entities.nationality:
                missing.append(
                    "nationality"
                )

            return tuple(
                missing
            )

        return ()

    # ==========================================================
    # EXISTING QUERY ANALYSIS
    # ==========================================================

    @classmethod
    def analyze(
        cls,
        text: str,
        *,
        recent_turns: list[
            dict[str, str]
        ] | tuple[
            dict[str, str],
            ...
        ] = (),
        current_destination: str | None = None,
    ) -> QueryState:

        # ------------------------------------------------------
        # Full refinement
        # ------------------------------------------------------

        refined = QueryRefinementService.refine(
            text,
            recent_turns=recent_turns,
            current_destination=current_destination,
        )

        # ------------------------------------------------------
        # Use retrieval-ready rewritten query
        # ------------------------------------------------------

        normalized = refined.rewritten

        # ------------------------------------------------------
        # Intent
        # ------------------------------------------------------

        intent = cls.detect_intent(
            normalized,
        )

        # ------------------------------------------------------
        # Entities
        # ------------------------------------------------------

        destination = cls.extract_destination(
            normalized,
        )

        origin = cls.extract_origin(
            normalized,
        )

        duration_days = cls.extract_duration(
            normalized,
        )

        traveler_count = cls.extract_traveler_count(
            normalized,
        )

        budget_amount, budget_currency = (
            cls.extract_budget(
                normalized,
            )
        )

        nationality = cls.extract_nationality(
            normalized,
        )

        interests = cls.extract_interests(
            normalized,
        )

        place_type = cls.place_type_for_intent(
            intent,
        )

        entities = QueryEntities(
            destination=(
                destination
                or current_destination
            ),

            origin=origin,

            duration_days=duration_days,

            traveler_count=traveler_count,

            budget_amount=budget_amount,

            budget_currency=budget_currency,

            nationality=nationality,

            interests=interests,

            place_type=place_type,
        )

        # ------------------------------------------------------
        # Travel evidence fallback
        # ------------------------------------------------------
        # If explicit phrase detection misses a natural-language
        # travel request, strong structured evidence can still
        # identify it as trip planning.
        #
        # Destination + duration is a high-confidence combination.
        # We deliberately do this AFTER entity extraction.

        if (
            intent == Intent.GENERAL_CHAT
            and entities.destination
            and entities.duration_days is not None
        ):
            intent = Intent.TRIP_PLANNING

        # Recalculate place type because the fallback can change
        # the primary intent.

        place_type = cls.place_type_for_intent(
            intent,
        )

        entities = QueryEntities(
            destination=entities.destination,
            origin=entities.origin,
            duration_days=entities.duration_days,
            traveler_count=entities.traveler_count,
            budget_amount=entities.budget_amount,
            budget_currency=entities.budget_currency,
            nationality=entities.nationality,
            interests=entities.interests,
            place_type=place_type,
        )

        # ------------------------------------------------------
        # Missing requirements
        # ------------------------------------------------------

        missing_slots = (
            cls.calculate_missing_slots(
                intent=intent,
                entities=entities,
            )
        )

        # ------------------------------------------------------
        # Confidence
        # ------------------------------------------------------
        # Intent evidence fallback is still a deterministic,
        # high-confidence travel signal when destination and
        # duration are both present.

        confidence = (
            0.90
            if (
                intent == Intent.TRIP_PLANNING
                and entities.destination
                and entities.duration_days is not None
            )
            else (
                0.85
                if intent != Intent.GENERAL_CHAT
                else 0.45
            )
        )

        return QueryState(
            original=text,

            normalized=normalized,

            language=refined.language,

            intent=intent,

            confidence=confidence,

            entities=entities,

            missing_slots=missing_slots,

            requires_clarification=bool(
                missing_slots
            ),
        )

    # ==========================================================
    # TRAVEL QUERY CONTRACT
    # ==========================================================

    @classmethod
    def analyze_travel_query(
        cls,
        text: str,
        *,
        recent_turns: list[
            dict[str, str]
        ] | tuple[
            dict[str, str],
            ...
        ] = (),
        current_destination: str | None = None,
    ) -> TravelQuery:
        """
        Build the new canonical TravelQuery contract from the
        existing QueryState pipeline.

        This is intentionally an adapter.

        We are NOT replacing QueryState yet.

        Existing code can continue using:

            analyze()

        New AI architecture can use:

            analyze_travel_query()

        This lets us migrate safely.
        """

        state = cls.analyze(
            text,
            recent_turns=recent_turns,
            current_destination=current_destination,
        )
        
        sub_intents = cls.detect_sub_intents(
            state.normalized,
            state.intent,
        )

        budget_level = cls.extract_budget_level(
            state.normalized,
        )

        detected_language, detected_languages, script = (
            cls.detect_query_language(
                text
            )
        )
        



        # ------------------------------------------------------
        # Date / time resolution
        # ------------------------------------------------------

        resolved_dates = DateTimeResolver.resolve(
            text,
        )


        travel_dates: TravelDateRange | None = None

        if resolved_dates.is_resolved:

            travel_dates = TravelDateRange(
                start_date=(
                    resolved_dates.start_date.isoformat()
                    if resolved_dates.start_date
                    else None
                ),

                end_date=(
                    resolved_dates.end_date.isoformat()
                    if resolved_dates.end_date
                    else None
                ),

                original_expression=(
                    resolved_dates.original_expression
                ),

                is_resolved=True,
            )


           
        # ------------------------------------------------------
        # Query entities
        # ------------------------------------------------------

        query_entities: list[QueryEntity] = []

        # ------------------------------------------------------
        # Destination
        # ------------------------------------------------------

        destination_entity: QueryEntity | None = None

        if state.entities.destination:

            destination_entity = QueryEntity(
                text=state.entities.destination,

                entity_type=EntityType.DESTINATION,

                canonical_name=(
                    state.entities.destination
                ),

                confidence=0.85,
            )

            query_entities.append(
                destination_entity
            )

        # ------------------------------------------------------
        # Origin
        # ------------------------------------------------------

        origin_entity: QueryEntity | None = None

        if state.entities.origin:

            origin_entity = QueryEntity(
                text=state.entities.origin,

                entity_type=EntityType.CITY,

                canonical_name=(
                    state.entities.origin
                ),

                confidence=0.80,
            )

            query_entities.append(
                origin_entity
            )

        # ------------------------------------------------------
        # Interests / preferences
        # ------------------------------------------------------

        preferences: list[TravelConstraint] = []

        for interest in state.entities.interests:

            preferences.append(
                TravelConstraint(
                    name="interest",

                    value=interest,

                    constraint_type=(
                        ConstraintType.SOFT
                    ),

                    confidence=0.75,

                    source="query",
                )
            )

       # ------------------------------------------------------
       # Budget
       # ------------------------------------------------------

        if (
          state.entities.budget_amount is not None
          or budget_level is not None
          ):

          budget_value = {
         "amount": state.entities.budget_amount,
         "currency": state.entities.budget_currency,
         "level": budget_level,
     }

          preferences.append(
            TravelConstraint(
            name="budget",
            value=budget_value,
            constraint_type=ConstraintType.SOFT,
            confidence=0.90,
            source="query",
        )
    )
        # ------------------------------------------------------
        # Duration
        # ------------------------------------------------------

        if state.entities.duration_days is not None:

            preferences.append(
                TravelConstraint(
                    name="duration_days",

                    value=(
                        state.entities.duration_days
                    ),

                    constraint_type=(
                        ConstraintType.HARD
                    ),

                    confidence=0.95,

                    source="query",
                )
            )

        # ------------------------------------------------------
        # Traveller count
        # ------------------------------------------------------

        if state.entities.traveler_count is not None:

            preferences.append(
                TravelConstraint(
                    name="traveler_count",

                    value=(
                        state.entities.traveler_count
                    ),

                    constraint_type=(
                        ConstraintType.HARD
                    ),

                    confidence=0.95,

                    source="query",
                )
            )

        # ------------------------------------------------------
        # Accommodation preference
        # ------------------------------------------------------

        if state.entities.place_type:

            preferences.append(
                TravelConstraint(
                    name="place_type",

                    value=(
                        state.entities.place_type
                    ),

                    constraint_type=(
                        ConstraintType.SOFT
                    ),

                    confidence=0.90,

                    source="intent",
                )
            )

       

        # ------------------------------------------------------
        # Confidence level
        # ------------------------------------------------------

        if state.confidence >= 0.80:

            confidence_level = (
                QueryConfidence.HIGH
            )

        elif state.confidence >= 0.60:

            confidence_level = (
                QueryConfidence.MEDIUM
            )

        else:

            confidence_level = (
                QueryConfidence.LOW
            )

        # ------------------------------------------------------
        # Action classification
        # ------------------------------------------------------

        action_level = ActionLevel.READ

        if state.intent == Intent.BOOKING_ACTION:

            action_level = (
                ActionLevel.CONSEQUENTIAL
            )

        # ------------------------------------------------------
        # Confirmation
        # ------------------------------------------------------

        confirmation_required = (
            action_level
            == ActionLevel.CONSEQUENTIAL
        )

        # ------------------------------------------------------
        # Processing trace
        # ------------------------------------------------------

        processing_steps = (
            "query_refinement",
            "intent_detection",
            "entity_extraction",
            "date_time_resolution",
            "requirement_analysis",
            "travel_query_mapping",
        )

        # ------------------------------------------------------
        # TravelQuery
        # ------------------------------------------------------

        return TravelQuery(
            # --------------------------------------------------
            # Original input
            # --------------------------------------------------

            raw_query=text,

            normalized_query=(
                state.normalized
            ),

            rewritten_query=(
                state.normalized
            ),

            # --------------------------------------------------
            # Language
            # --------------------------------------------------

            language=detected_language,

            languages=detected_languages,

            script=script,

            # --------------------------------------------------
            # Intent
            # --------------------------------------------------

            intent=state.intent.value,

            sub_intents=sub_intents,

            # --------------------------------------------------
            # Entities
            # --------------------------------------------------

            entities=tuple(
                query_entities
            ),

            origin=origin_entity,

            destination=destination_entity,

            # --------------------------------------------------
            # Travel
            # --------------------------------------------------


            dates=travel_dates,

            duration_days=(
                state.entities.duration_days
            ),

            traveler_count=(
                state.entities.traveler_count
            ),

            # --------------------------------------------------
            # Budget
            # --------------------------------------------------

            budget_amount=(
                state.entities.budget_amount
            ),

            budget_currency=(
                state.entities.budget_currency
            ),

            budget_level=budget_level,

            # --------------------------------------------------
            # Preferences
            # --------------------------------------------------

            preferences=tuple(
                preferences
            ),

            # --------------------------------------------------
            # Requirements
            # --------------------------------------------------

            missing_information=(
                tuple(state.missing_slots)
            ),

            # --------------------------------------------------
            # Action
            # --------------------------------------------------

            action_level=action_level,

            confirmation_required=(
                confirmation_required
            ),

            # --------------------------------------------------
            # Confidence
            # --------------------------------------------------

            confidence=state.confidence,

            confidence_level=(
                confidence_level
            ),

            # --------------------------------------------------
            # Context
            # --------------------------------------------------

            conversation_used=bool(
                recent_turns
            ),

            active_trip_used=(
                current_destination is not None
            ),

            # --------------------------------------------------
            # Observability
            # --------------------------------------------------

            processing_steps=(
                processing_steps
            ),
        )
    


        
# ==========================================================
# REQUIREMENT POLICY
# ==========================================================


class RequirementPolicy:
    """
    Converts missing requirements into the smallest useful
    clarification question.

    The system should never ask for every planner field
    in one message.
    """

    @staticmethod
    def minimum_question(
        state: QueryState,
    ) -> str | None:

        if not state.missing_slots:
            return None

        # ------------------------------------------------------
        # Trip planning
        # ------------------------------------------------------

        if state.intent in {
            Intent.TRIP_PLANNING,
            Intent.ITINERARY_GENERATION,
        }:

            if "destination" in state.missing_slots:

                return (
                    "Absolutely. "
                    "Where would you like to go?"
                )

            if "duration_days" in state.missing_slots:

                return (
                    "Great. "
                    "How many days are you planning "
                    "to travel?"
                )

        # ------------------------------------------------------
        # Policy
        # ------------------------------------------------------

        if state.intent in {
            Intent.VISA_POLICY,
            Intent.TRAVEL_POLICY,
        }:

            if "destination" in state.missing_slots:

                return (
                    "Which country are you "
                    "planning to visit?"
                )

            if "nationality" in state.missing_slots:

                return (
                    "Which passport or nationality "
                    "should I use for the travel "
                    "requirements?"
                )

        # ------------------------------------------------------
        # Route
        # ------------------------------------------------------

        if state.intent == Intent.ROUTE_PLANNING:

            if "origin" in state.missing_slots:

                return (
                    "Where are you travelling from?"
                )

            if "destination" in state.missing_slots:

                return (
                    "Where are you travelling to?"
                )

        return (
            "Could you tell me a little more about "
            "what you would like to plan?"
        )


__all__ = [
    "QueryUnderstanding",
    "RequirementPolicy",
]