"""
Environment configuration.

This module determines which environment configuration
(development, staging, production) is active.
"""

from __future__ import annotations

import os
from enum import Enum


class Environment(str, Enum):
    DEVELOPMENT = "development"
    STAGING = "staging"
    PRODUCTION = "production"


DEFAULT_ENVIRONMENT = Environment.DEVELOPMENT.value


def get_environment() -> Environment:
    """
    Returns the current application environment.

    Reads APP_ENV from the operating system.

    Defaults to DEVELOPMENT.
    """

    value = os.getenv("APP_ENV", DEFAULT_ENVIRONMENT).lower()

    try:
        return Environment(value)
    except ValueError:
        return Environment.DEVELOPMENT


CURRENT_ENVIRONMENT = get_environment()


def is_development() -> bool:
    return CURRENT_ENVIRONMENT == Environment.DEVELOPMENT


def is_staging() -> bool:
    return CURRENT_ENVIRONMENT == Environment.STAGING


def is_production() -> bool:
    return CURRENT_ENVIRONMENT == Environment.PRODUCTION