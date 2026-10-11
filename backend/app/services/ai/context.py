from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Iterable

from .contracts import DataSensitivity


# ==========================================================
# LOCATION CONTEXT
# ==========================================================

@dataclass(slots=True)
class LocationContext:
    """
    Location known by the application.

    Exact coordinates are intentionally kept server-side unless
    a specific location/routing capability requires them.
    """

    country: str | None = None

    state: str | None = None

    city: str | None = None

    latitude: float | None = None

    longitude: float | None = None

    # city | area | exact
    precision: str = "city"

    # Whether the user has permitted location use.
    consented: bool = False


# ==========================================================
# USER PREFERENCES
# ==========================================================

@dataclass(slots=True)
class PreferencesContext:
    """
    Normalized preferences derived from application data.

    These are useful signals, not a raw user profile dump.
    """

    travel_styles: tuple[str, ...] = ()

    interests: tuple[str, ...] = ()

    food_preferences: tuple[str, ...] = ()

    accommodation_preferences: tuple[str, ...] = ()

    transport_preferences: tuple[str, ...] = ()

    budget_currency: str | None = None

    budget_range: str | None = None


# ==========================================================
# TRIP SUMMARY
# ==========================================================

@dataclass(slots=True)
class TripSummary:
    """
    Small derived representation of a previous/current trip.

    We intentionally do NOT copy the complete Trip model here.
    """

    destination: str | None = None

    duration_days: int | None = None

    travel_style: str | None = None

    status: str | None = None

    preference_tags: tuple[str, ...] = ()


# ==========================================================
# RICH SERVER-SIDE CONTEXT
# ==========================================================

@dataclass(slots=True)
class UserContextSnapshot:
    """
    Rich internal context.

    IMPORTANT:
    This object must never be serialized directly into an LLM prompt.
    """

    user_id: str

    location: LocationContext | None = None

    preferences: PreferencesContext = field(
        default_factory=PreferencesContext,
    )

    trip_history: tuple[TripSummary, ...] = ()

    # Small recent conversation representation.
    recent_turns: tuple[dict[str, str], ...] = ()

    # Current trip, if the user is modifying/planning one.
    current_trip_id: str | None = None

    current_trip_summary: str | None = None


# ==========================================================
# LLM-SAFE CONTEXT PACKET
# ==========================================================

@dataclass(slots=True)
class ContextPacket:
    """
    Minimal provider-facing context.

    Only this object is allowed to cross the LLM boundary.
    """

    origin_city: str | None = None

    origin_country: str | None = None

    location_consent: bool = False

    destination: str | None = None

    traveler_count: int | None = None

    duration_days: int | None = None

    budget_currency: str | None = None

    budget_range: str | None = None

    travel_styles: tuple[str, ...] = ()

    interests: tuple[str, ...] = ()

    food_preferences: tuple[str, ...] = ()

    accommodation_preferences: tuple[str, ...] = ()

    transport_preferences: tuple[str, ...] = ()

    relevant_trip_patterns: tuple[str, ...] = ()

    conversation_summary: str | None = None

    evidence_ids: tuple[str, ...] = ()


# ==========================================================
# CONTEXT FIREWALL
# ==========================================================

class ContextFirewall:
    """
    Enforces the boundary between private application data
    and provider/LLM context.

    The application can know much more than the LLM needs to know.
    """

    # These fields should NEVER cross the provider boundary.
    FORBIDDEN_KEYS = frozenset(
        {
            # Authentication / security
            "password",
            "password_hash",
            "access_token",
            "refresh_token",
            "token",
            "secret",

            # Direct personal/contact information
            "email",
            "phone",
            "address",

            # Financial information
            "card_number",
            "payment_method",

            # Internal identifiers / infrastructure
            "user_id",
            "database_id",
            "internal_flags",
        }
    )

    # ======================================================
    # BUILD SAFE PACKET
    # ======================================================

    @classmethod
    def build_packet(
        cls,
        snapshot: UserContextSnapshot,
        *,
        destination: str | None = None,
        traveler_count: int | None = None,
        duration_days: int | None = None,
        evidence_ids: Iterable[str] = (),
    ) -> ContextPacket:
        """
        Convert rich internal context into minimal LLM-safe context.
        """

        location = snapshot.location

        # --------------------------------------------------
        # Location
        # --------------------------------------------------

        origin_city = None
        origin_country = None
        location_consent = False

        if location is not None:
            origin_city = location.city
            origin_country = location.country
            location_consent = location.consented

        # --------------------------------------------------
        # Trip history
        # --------------------------------------------------

        trip_patterns = tuple(
            cls._trip_pattern(trip)
            for trip in snapshot.trip_history[:5]
        )

        # --------------------------------------------------
        # Build provider-safe packet
        # --------------------------------------------------

        return ContextPacket(
            origin_city=origin_city,
            origin_country=origin_country,
            location_consent=location_consent,
            destination=destination,
            traveler_count=traveler_count,
            duration_days=duration_days,
            budget_currency=snapshot.preferences.budget_currency,
            budget_range=snapshot.preferences.budget_range,
            travel_styles=snapshot.preferences.travel_styles,
            interests=snapshot.preferences.interests,
            food_preferences=snapshot.preferences.food_preferences,
            accommodation_preferences=(
                snapshot.preferences.accommodation_preferences
            ),
            transport_preferences=(
                snapshot.preferences.transport_preferences
            ),
            relevant_trip_patterns=trip_patterns,
            conversation_summary=snapshot.current_trip_summary,
            evidence_ids=tuple(evidence_ids),
        )

    # ======================================================
    # TRIP SUMMARIZATION
    # ======================================================

    @staticmethod
    def _trip_pattern(
        trip: TripSummary,
    ) -> str:
        """
        Convert a trip summary into a small derived signal.
        """

        parts: list[str] = []

        if trip.destination:
            parts.append(
                f"destination={trip.destination}"
            )

        if trip.duration_days:
            parts.append(
                f"duration={trip.duration_days}d"
            )

        if trip.travel_style:
            parts.append(
                f"style={trip.travel_style}"
            )

        if trip.preference_tags:
            parts.append(
                "preferences="
                + ",".join(trip.preference_tags)
            )

        if trip.status:
            parts.append(
                f"status={trip.status}"
            )

        return "; ".join(parts)

    # ======================================================
    # SERIALIZE SAFE PAYLOAD
    # ======================================================

    @classmethod
    def to_payload(
        cls,
        packet: ContextPacket,
    ) -> dict[str, Any]:
        """
        Convert the safe packet into a plain dictionary suitable
        for an LLM/provider request.
        """

        payload: dict[str, Any] = {}

        for field_name in packet.__dataclass_fields__:
            value = getattr(packet, field_name)

            # Avoid sending empty/null values unnecessarily.
            if value in (
                None,
                "",
                (),
                [],
            ):
                continue

            payload[field_name] = value

        cls.assert_safe(payload)

        return payload

    # ======================================================
    # SAFETY VALIDATION
    # ======================================================

    @classmethod
    def assert_safe(
        cls,
        payload: dict[str, Any],
    ) -> None:
        """
        Fail closed if a forbidden field is accidentally introduced.
        """

        leaked = cls.FORBIDDEN_KEYS.intersection(
            payload.keys()
        )

        if leaked:
            raise ValueError(
                "Sensitive fields crossed the LLM boundary: "
                f"{sorted(leaked)}"
            )

        def walk(value: Any) -> None:
            if isinstance(value, dict):
                nested_leaks = cls.FORBIDDEN_KEYS.intersection(
                    value.keys()
                )

                if nested_leaks:
                    raise ValueError(
                        "Sensitive nested fields crossed "
                        "the LLM boundary: "
                        f"{sorted(nested_leaks)}"
                    )

                for child in value.values():
                    walk(child)

            elif isinstance(value, (list, tuple)):
                for child in value:
                    walk(child)

        walk(payload)


# Keep the sensitivity enum imported and available for future
# policy/permission checks without duplicating its definition.
__all__ = [
    "DataSensitivity",
    "LocationContext",
    "PreferencesContext",
    "TripSummary",
    "UserContextSnapshot",
    "ContextPacket",
    "ContextFirewall",
]
