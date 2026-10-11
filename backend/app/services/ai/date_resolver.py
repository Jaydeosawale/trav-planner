from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from typing import Optional


@dataclass(slots=True)
class ResolvedDateRange:
    """
    Internal representation of a resolved travel date expression.
    """

    start_date: date | None = None
    end_date: date | None = None

    original_expression: str | None = None

    is_resolved: bool = False

    confidence: float = 0.0

    resolution_type: str = "unknown"


class DateTimeResolver:
    """
    Resolves natural-language travel date expressions.

    Examples:

        next weekend
        this weekend
        tomorrow
        next Friday
        this Friday
        15 Aug
        15 August 2026
        15/08/2026
        15 Aug to 18 Aug
        20 August - 23 August

    The resolver deliberately keeps the original expression.
    """

    WEEKDAYS = {
        "monday": 0,
        "tuesday": 1,
        "wednesday": 2,
        "thursday": 3,
        "friday": 4,
        "saturday": 5,
        "sunday": 6,
    }

    MONTHS = {
        "january": 1,
        "february": 2,
        "march": 3,
        "april": 4,
        "may": 5,
        "june": 6,
        "july": 7,
        "august": 8,
        "september": 9,
        "october": 10,
        "november": 11,
        "december": 12,
    }

    MONTH_ALIASES = {
        "jan": 1,
        "feb": 2,
        "mar": 3,
        "apr": 4,
        "may": 5,
        "jun": 6,
        "jul": 7,
        "aug": 8,
        "sep": 9,
        "sept": 9,
        "oct": 10,
        "nov": 11,
        "dec": 12,
    }

    @classmethod
    def resolve(
        cls,
        text: str,
        reference_date: date | None = None,
    ) -> ResolvedDateRange:

        if not text:
            return ResolvedDateRange()

        reference_date = (
            reference_date
            or date.today()
        )

        query = cls._normalize(text)

        # --------------------------------------------------
        # Date range
        # --------------------------------------------------

        result = cls._resolve_date_range(
            query,
            reference_date,
        )

        if result:
            return result

        # --------------------------------------------------
        # Relative days
        # --------------------------------------------------

        result = cls._resolve_relative_day(
            query,
            reference_date,
        )

        if result:
            return result

        # --------------------------------------------------
        # Weekend
        # --------------------------------------------------

        result = cls._resolve_weekend(
            query,
            reference_date,
        )

        if result:
            return result

        # --------------------------------------------------
        # Weekday
        # --------------------------------------------------

        result = cls._resolve_weekday(
            query,
            reference_date,
        )

        if result:
            return result

        # --------------------------------------------------
        # Explicit date
        # --------------------------------------------------

        result = cls._resolve_explicit_date(
            query,
            reference_date,
        )

        if result:
            return result

        return ResolvedDateRange(
            original_expression=text,
            is_resolved=False,
            confidence=0.0,
        )

    # ======================================================
    # NORMALIZATION
    # ======================================================

    @staticmethod
    def _normalize(text: str) -> str:

        value = text.lower().strip()

        value = re.sub(
            r"\s+",
            " ",
            value,
        )

        value = value.replace(
            "–",
            "-",
        )

        value = value.replace(
            "—",
            "-",
        )

        return value

    # ======================================================
    # RELATIVE DAYS
    # ======================================================

    @classmethod
    def _resolve_relative_day(
        cls,
        query: str,
        reference_date: date,
    ) -> Optional[ResolvedDateRange]:

        expressions = {
            "today": 0,
            "tomorrow": 1,
            "day after tomorrow": 2,

            # Hindi transliteration
            "aaj": 0,
            "kal": 1,
            "parso": 2,

            # Marathi transliteration
            "udya": 1,
            "udya": 1,
            "parva": 2,
        }

        for expression, offset in expressions.items():

            if expression in query:

                target = (
                    reference_date
                    + timedelta(days=offset)
                )

                return ResolvedDateRange(
                    start_date=target,
                    end_date=target,
                    original_expression=expression,
                    is_resolved=True,
                    confidence=0.98,
                    resolution_type="relative_day",
                )

        return None

    # ======================================================
    # WEEKEND
    # ======================================================

    @classmethod
    def _resolve_weekend(
        cls,
        query: str,
        reference_date: date,
    ) -> Optional[ResolvedDateRange]:

        # IMPORTANT:
        # Specific/longer expressions must be checked before
        # generic expressions such as "ya weekend".

        next_weekend_patterns = (
    "next weekend",
    "next wknd",
    "next wk end",
    "nxt weekend",
    "nxt wknd",
    "nxt wk end",
    "pudhchya weekend",
    "pudchya weekend",
    "pudhchya wknd",
    "pudchya wknd",
    "pudhchya wk end",
    "pudchya wk end",
    "aglya weekend",
    "agli weekend",
)

        this_weekend_patterns = (
            "this weekend",
            "this wknd",
            "this wk end",
            "ya weekend",
            "ya wknd",
            "hya weekend",
            "hya wknd",
        )

        expression = cls._find_phrase(
            query,
            next_weekend_patterns,
        )

        if expression:
            return cls._weekend_range(
                reference_date=reference_date,
                next_weekend=True,
                expression=expression,
            )

        expression = cls._find_phrase(
            query,
            this_weekend_patterns,
        )

        if expression:
            return cls._weekend_range(
                reference_date=reference_date,
                next_weekend=False,
                expression=expression,
            )

        return None

    @classmethod
    def _weekend_range(
        cls,
        reference_date: date,
        next_weekend: bool,
        expression: str,
    ) -> ResolvedDateRange:

        weekday = reference_date.weekday()

        # Monday-Friday:
        #
        # this weekend = upcoming Saturday/Sunday
        #
        # Saturday/Sunday:
        #
        # this weekend = current Saturday/Sunday

        if weekday <= 4:

            days_until_saturday = 5 - weekday

            saturday = (
                reference_date
                + timedelta(
                    days=days_until_saturday
                )
            )

        else:

            days_since_saturday = weekday - 5

            saturday = (
                reference_date
                - timedelta(
                    days=days_since_saturday
                )
            )

        if next_weekend:
            saturday += timedelta(days=7)

        sunday = saturday + timedelta(days=1)

        return ResolvedDateRange(
            start_date=saturday,
            end_date=sunday,
            original_expression=expression,
            is_resolved=True,
            confidence=0.97,
            resolution_type="weekend",
        )

    @staticmethod
    def _find_phrase(
        query: str,
        patterns: tuple[str, ...],
    ) -> str | None:

        # Sort longest first so:
        #
        # "pudhchya weekend"
        #
        # is checked before:
        #
        # "ya weekend"

        for pattern in sorted(
            patterns,
            key=len,
            reverse=True,
        ):

            if pattern in query:
                return pattern

        return None
    # ======================================================
    # WEEKDAY
    # ======================================================

    @classmethod
    def _resolve_weekday(
        cls,
        query: str,
        reference_date: date,
    ) -> Optional[ResolvedDateRange]:

        for weekday_name, weekday_number in (
            cls.WEEKDAYS.items()
        ):

            if weekday_name not in query:
                continue

            is_next = (
                f"next {weekday_name}" in query
                or f"coming {weekday_name}" in query
            )

            is_this = (
                f"this {weekday_name}" in query
            )

            if not (
                is_next
                or is_this
            ):
                continue

            current_weekday = reference_date.weekday()

            days_ahead = (
                weekday_number - current_weekday
            ) % 7

            if is_next:
                # "next Friday" means the Friday of the
                # following week, not merely the next
                # upcoming Friday.
                days_ahead += 7

            target = (
                reference_date
                + timedelta(days=days_ahead)
            )

            if is_next:

                # "next Friday" should mean the Friday
                # in the following week when today is Friday.
                if days_ahead == 0:
                    days_ahead = 7

                target = (
                    reference_date
                    + timedelta(days=days_ahead)
                )

            else:

                target = (
                    reference_date
                    + timedelta(days=days_ahead)
                )

            return ResolvedDateRange(
                start_date=target,
                end_date=target,
                original_expression=(
                    f"next {weekday_name}"
                    if is_next
                    else f"this {weekday_name}"
                ),
                is_resolved=True,
                confidence=0.96,
                resolution_type="weekday",
            )

        return None

    # ======================================================
    # EXPLICIT DATE RANGE
    # ======================================================

    @classmethod
    def _resolve_date_range(
        cls,
        query: str,
        reference_date: date,
    ) -> Optional[ResolvedDateRange]:

        # Example:
        #
        # 15 Aug to 18 Aug
        # 15 August - 18 August
        #
        pattern = re.compile(
            r"\b"
            r"(\d{1,2})"
            r"\s+"
            r"([a-z]+)"
            r"\s*"
            r"(?:to|-|until)"
            r"\s*"
            r"(\d{1,2})"
            r"\s+"
            r"([a-z]+)"
            r"(?:\s+(\d{4}))?"
            r"\b",
            re.IGNORECASE,
        )

        match = pattern.search(query)

        if not match:
            return None

        start_day = int(match.group(1))
        start_month_name = match.group(2).lower()

        end_day = int(match.group(3))
        end_month_name = match.group(4).lower()

        year_text = match.group(5)

        start_month = (
            cls.MONTHS.get(
                start_month_name,
                cls.MONTH_ALIASES.get(
                    start_month_name,
                ),
            )
        )

        end_month = (
            cls.MONTHS.get(
                end_month_name,
                cls.MONTH_ALIASES.get(
                    end_month_name,
                ),
            )
        )

        if not start_month or not end_month:
            return None

        year = (
            int(year_text)
            if year_text
            else reference_date.year
        )

        try:

            start = date(
                year,
                start_month,
                start_day,
            )

            end = date(
                year,
                end_month,
                end_day,
            )

        except ValueError:
            return None

        return ResolvedDateRange(
            start_date=start,
            end_date=end,
            original_expression=match.group(0),
            is_resolved=True,
            confidence=0.98,
            resolution_type="explicit_range",
        )

    # ======================================================
    # EXPLICIT SINGLE DATE
    # ======================================================

    @classmethod
    def _resolve_explicit_date(
        cls,
        query: str,
        reference_date: date,
    ) -> Optional[ResolvedDateRange]:

        # --------------------------------------------------
        # DD/MM/YYYY
        # --------------------------------------------------

        match = re.search(
            r"\b(\d{1,2})[/-](\d{1,2})(?:[/-](\d{4}))?\b",
            query,
        )

        if match:

            day = int(match.group(1))
            month = int(match.group(2))

            year = (
                int(match.group(3))
                if match.group(3)
                else reference_date.year
            )

            try:

                target = date(
                    year,
                    month,
                    day,
                )

                return ResolvedDateRange(
                    start_date=target,
                    end_date=target,
                    original_expression=match.group(0),
                    is_resolved=True,
                    confidence=0.98,
                    resolution_type="explicit_date",
                )

            except ValueError:
                pass

        # --------------------------------------------------
        # DD Month YYYY
        # --------------------------------------------------

        pattern = re.compile(
            r"\b(\d{1,2})\s+([a-z]+)"
            r"(?:\s+(\d{4}))?\b",
            re.IGNORECASE,
        )

        match = pattern.search(query)

        if not match:
            return None

        day = int(match.group(1))
        month_name = match.group(2).lower()

        month = cls.MONTHS.get(
            month_name,
            cls.MONTH_ALIASES.get(
                month_name,
            ),
        )

        if month is None:
            return None

        year = (
            int(match.group(3))
            if match.group(3)
            else reference_date.year
        )

        try:

            target = date(
                year,
                month,
                day,
            )

        except ValueError:
            return None

        return ResolvedDateRange(
            start_date=target,
            end_date=target,
            original_expression=match.group(0),
            is_resolved=True,
            confidence=0.98,
            resolution_type="explicit_date",
        )

    # ======================================================
    # HELPERS
    # ======================================================

    @staticmethod
    def _matched_expression(
        query: str,
        patterns: tuple[str, ...],
    ) -> str:

        for pattern in patterns:

            if pattern in query:
                return pattern

        return query