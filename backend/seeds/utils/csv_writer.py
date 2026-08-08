"""
CSV Writer.
"""

from __future__ import annotations

import csv
from pathlib import Path
from typing import Any

from seeds.utils.data_writer import DataWriter


class CsvWriter(DataWriter):
    """
    CSV dataset writer.
    """

    def write(
        self,
        file_path: str | Path,
        data: list[dict[str, Any]],
    ) -> None:

        if not data:
            return

        path = Path(file_path)

        path.parent.mkdir(
            parents=True,
            exist_ok=True,
        )

        with path.open(
            "w",
            encoding="utf-8",
            newline="",
        ) as file:

            writer = csv.DictWriter(
                file,
                fieldnames=data[0].keys(),
            )

            writer.writeheader()
            writer.writerows(data)