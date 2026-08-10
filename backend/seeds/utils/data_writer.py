"""
Abstract data writer.
"""

from __future__ import annotations

from abc import ABC
from abc import abstractmethod
from pathlib import Path
from typing import Any


class DataWriter(ABC):
    """
    Base class for dataset writers.
    """

    @abstractmethod
    def write(
        self,
        file_path: str | Path,
        data: list[dict[str, Any]],
    ) -> None:
        """
        Write dataset.
        """
        raise NotImplementedError