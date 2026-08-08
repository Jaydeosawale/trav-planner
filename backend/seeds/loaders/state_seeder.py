"""
State Seeder.
"""

from __future__ import annotations

from app.modules.state.model import State

from seeds.constants import DataPaths
from seeds.loaders.base import BaseSeeder
from seeds.utils.json_loader import JsonLoader
from seeds.utils.lookups import LookupCache
from seeds.utils.report import SeederReport
from seeds.utils.registry import SeederRegistry


@SeederRegistry.register("state")
class StateSeeder(BaseSeeder):
    """
    Seed states into database.
    """

    async def seed(self) -> None:
        """
        Seed states.
        """

        loader = JsonLoader()

        states = loader.load(
            DataPaths.STATES,
        )

        report = SeederReport(
            "State Seeder",
        )

        # ==========================================================
        # Load Country Cache
        # ==========================================================

        country_lookup = await LookupCache.countries(
            self.db,
        )

        # ==========================================================
        # Load Existing State Cache
        # ==========================================================

        state_lookup = await LookupCache.states(
            self.db,
        )

        # ==========================================================
        # Seed States
        # ==========================================================

        for item in states:

            # ------------------------------------------------------
            # Find Country
            # ------------------------------------------------------

            country = country_lookup.get(
                item["country_iso2"],
            )

            if country is None:
                print(
                    f"Country not found: "
                    f"{item['country_iso2']}"
                )

                report.fail()
                continue

            # ------------------------------------------------------
            # State Identity
            # ------------------------------------------------------
            #
            # State identity is:
            #
            #     country_id + state_code
            #
            # State name is NOT used for uniqueness because
            # the source data can contain multiple states with
            # the same name under the same country.
            # ------------------------------------------------------

            state_key = (
                country.id,
                item["code"],
            )

            # ------------------------------------------------------
            # Duplicate Check
            # ------------------------------------------------------

            if state_key in state_lookup:
                report.skip()
                continue

            # ------------------------------------------------------
            # Create State
            # ------------------------------------------------------

            state = State(
                country_id=country.id,
                name=item["name"],
                code=item["code"],
                is_active=True,
            )

            self.db.add(state)

            # ------------------------------------------------------
            # Update Cache
            # ------------------------------------------------------
            #
            # This is important because all states are committed
            # together at the end. The database query cannot be
            # relied upon to detect another pending state in the
            # same import.
            # ------------------------------------------------------

            state_lookup[state_key] = state

            report.success()

        # ==========================================================
        # Commit
        # ==========================================================

        await self.db.commit()

        report.print()