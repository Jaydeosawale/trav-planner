"""
Seed data paths.
"""

from __future__ import annotations

from pathlib import Path


class DataPaths:
    """
    Seed data locations.
    """

    ROOT = Path("seeds/data")

    RAW = ROOT / "raw"

    PROCESSED = ROOT / "processed"

    # ==========================================================
    # Raw Datasets
    # ==========================================================

    RAW_COUNTRIES = RAW / "countries.json"

    RAW_STATES = RAW / "states.json"

    RAW_CITIES = RAW / "cities.json"

    # ==========================================================
    # Processed Datasets
    # ==========================================================

    COUNTRIES = PROCESSED / "countries.json"

    STATES = PROCESSED / "states.json"

    CITIES = PROCESSED / "cities.json"

    CATEGORIES = PROCESSED / "categories.json"

    AMENITIES = PROCESSED / "amenities.json"

    LANGUAGES = PROCESSED / "languages.json"

    CURRENCIES = PROCESSED / "currencies.json"
    DESTINATIONS = PROCESSED / "destinations.json"
