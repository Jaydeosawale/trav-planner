"""
Abstract data loader.
"""

from __future__ import annotations

from abc import ABC
from abc import abstractmethod
from pathlib import Path
from typing import Any


class DataLoader(ABC):
    """
    Base class for dataset loaders.
    """

    @abstractmethod
    def load(
        self,
        file_path: str | Path,
    ) -> list[dict[str, Any]]:
        """
        Load dataset.
        """
        raise NotImplementedError