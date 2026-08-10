"""
JSON Writer.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from seeds.utils.data_writer import DataWriter


class JsonWriter(DataWriter):
    """
    JSON dataset writer.
    """

    def write(
        self,
        file_path: str | Path,
        data: list[dict[str, Any]],
    ) -> None:

        path = Path(file_path)

        path.parent.mkdir(
            parents=True,
            exist_ok=True,
        )

        with path.open(
            "w",
            encoding="utf-8",
        ) as file:

            json.dump(
                data,
                file,
                indent=4,
                ensure_ascii=False,
            )