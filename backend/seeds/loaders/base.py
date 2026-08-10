"""
Base Seeder.
"""

from __future__ import annotations

from abc import ABC
from abc import abstractmethod

from sqlalchemy.ext.asyncio import AsyncSession


class BaseSeeder(ABC):
    """
    Base class for all seeders.
    """

    def __init__(
        self,
        db: AsyncSession,
    ) -> None:
        self.db = db

    async def before_seed(self) -> None:
        """
        Hook executed before seeding starts.
        """

    @abstractmethod
    async def seed(self) -> None:
        """
        Execute seeding.
        """
        raise NotImplementedError

    async def after_seed(self) -> None:
        """
        Hook executed after seeding finishes.
        """

    async def run(self) -> None:
        """
        Execute complete seeding lifecycle.
        """

        await self.before_seed()

        await self.seed()

        await self.after_seed()