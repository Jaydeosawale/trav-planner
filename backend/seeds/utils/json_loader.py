"""
JSON Loader.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from seeds.utils.data_loader import DataLoader


class JsonLoader(DataLoader):
    """
    JSON dataset loader.
    """

    def load(
        self,
        file_path: str | Path,
    ) -> list[dict[str, Any]]:

        path = Path(file_path)

        if not path.exists():
            raise FileNotFoundError(
                f"File not found: {path}"
            )

        with path.open(
            "r",
            encoding="utf-8",
        ) as file:

            return json.load(file)