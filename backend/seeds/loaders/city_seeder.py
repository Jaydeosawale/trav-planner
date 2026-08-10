"""
City Seeder.
"""

from __future__ import annotations

from app.modules.city.model import City

from seeds.constants import DataPaths
from seeds.loaders.base import BaseSeeder
from seeds.utils.json_loader import JsonLoader
from seeds.utils.lookups import LookupCache
from seeds.utils.report import SeederReport
from seeds.utils.registry import SeederRegistry


@SeederRegistry.register("city")
class CitySeeder(BaseSeeder):
    """
    Seed cities into database.
    """

    async def seed(self) -> None:
        """
        Seed cities.
        """

        loader = JsonLoader()

        cities = loader.load(
            DataPaths.CITIES,
        )

        report = SeederReport(
            "City Seeder",
        )

        # ==========================================================
        # Load Lookup Caches
        # ==========================================================

        country_lookup = await LookupCache.countries(
            self.db,
        )

        state_lookup = await LookupCache.states(
            self.db,
        )

        city_lookup = await LookupCache.cities(
            self.db,
        )

        # ==========================================================
        # Seed Cities
        # ==========================================================

        for item in cities:

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
            # Find State
            # ------------------------------------------------------

            state = state_lookup.get(
                (
                    country.id,
                    item["state_code"],
                )
            )

            if state is None:
                print(
                    f"State not found: "
                    f"{item['country_iso2']} "
                    f"{item['state_code']} "
                    f"{item['state_name']}"
                )
                report.fail()
                continue

            # ------------------------------------------------------
            # Duplicate Check
            # ------------------------------------------------------

            if (
                state.id,
                item["name"],
            ) in city_lookup:

                report.skip()
                continue

            # ------------------------------------------------------
            # Create City
            # ------------------------------------------------------

            city = City(
                country_id=country.id,
                state_id=state.id,
                name=item["name"],
                latitude=item.get("latitude"),
                longitude=item.get("longitude"),
                is_active=True,
            )

            self.db.add(city)

            # Update cache to avoid duplicates
            city_lookup[
                (
                    state.id,
                    city.name,
                )
            ] = city

            report.success()

        await self.db.commit()

        report.print()