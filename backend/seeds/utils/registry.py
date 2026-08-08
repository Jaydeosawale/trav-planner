"""
Seeder Registry.
"""

from __future__ import annotations

from typing import Type

from seeds.loaders.base import BaseSeeder


class SeederRegistry:
    """
    Registry for all seeders.
    """

    _registry: dict[str, Type[BaseSeeder]] = {}

    @classmethod
    def register(
        cls,
        name: str,
    ):
        """
        Register a seeder.
        """

        def decorator(
            seeder_cls: Type[BaseSeeder],
        ) -> Type[BaseSeeder]:

            cls._registry[name.lower()] = seeder_cls

            return seeder_cls

        return decorator

    @classmethod
    def get(
        cls,
        name: str,
    ) -> Type[BaseSeeder] | None:
        """
        Return registered seeder.
        """

        return cls._registry.get(
            name.lower(),
        )

    @classmethod
    def all(
        cls,
    ) -> dict[str, Type[BaseSeeder]]:
        """
        Return all registered seeders.
        """

        return cls._registry