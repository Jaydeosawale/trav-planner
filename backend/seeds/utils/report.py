"""
Seeder Report Utility.
"""

from __future__ import annotations

import time


class SeederReport:
    """
    Prints standardized seeder reports.
    """

    def __init__(
        self,
        name: str,
    ) -> None:
        self.name = name

        self.created = 0
        self.skipped = 0
        self.failed = 0

        self.start_time = time.perf_counter()

    def success(self) -> None:
        self.created += 1

    def skip(self) -> None:
        self.skipped += 1

    def fail(self) -> None:
        self.failed += 1

    def print(self) -> None:
        duration = time.perf_counter() - self.start_time

        print()

        print("=" * 60)
        print(self.name)
        print("=" * 60)
        print(f"Created : {self.created}")
        print(f"Skipped : {self.skipped}")
        print(f"Failed  : {self.failed}")
        print(f"Duration: {duration:.2f} sec")
        print("=" * 60)