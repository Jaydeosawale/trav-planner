"""
Base Converter.
"""

from __future__ import annotations

from abc import ABC
from abc import abstractmethod
from pathlib import Path
from typing import Any

from seeds.utils.data_loader import DataLoader
from seeds.utils.data_writer import DataWriter


class BaseConverter(ABC):
    """
    Base class for all dataset converters.
    """

    def __init__(
        self,
        loader: DataLoader,
        writer: DataWriter,
    ) -> None:
        self.loader = loader
        self.writer = writer

    async def before_convert(self) -> None:
        """
        Hook executed before conversion.
        """

    @abstractmethod
    async def convert(self) -> None:
        """
        Convert dataset.
        """
        raise NotImplementedError

    async def after_convert(self) -> None:
        """
        Hook executed after conversion.
        """

    async def run(self) -> None:
        """
        Execute complete conversion lifecycle.
        """

        await self.before_convert()
        await self.convert()
        await self.after_convert()

    def load_data(
        self,
        file_path: str | Path,
    ) -> list[dict[str, Any]]:
        """
        Load dataset using configured loader.
        """

        return self.loader.load(file_path)

    def write_data(
        self,
        file_path: str | Path,
        data: list[dict[str, Any]],
    ) -> None:
        """
        Write dataset using configured writer.
        """

        self.writer.write(
            file_path,
            data,
        )