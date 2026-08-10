"""
Country Seeder.
"""

from __future__ import annotations

from sqlalchemy import select

from app.modules.country.model import Country

from seeds.constants import DataPaths
from seeds.loaders.base import BaseSeeder
from seeds.utils.json_loader import JsonLoader
from seeds.utils.report import SeederReport
from seeds.utils.registry import SeederRegistry

@SeederRegistry.register("country")
class CountrySeeder(BaseSeeder):
    """
    Seed countries into database.
    """

    async def seed(self) -> None:
        """
        Seed countries.
        """

        loader = JsonLoader()

        countries = loader.load(
          DataPaths.COUNTRIES,
        )

        report = SeederReport(
            "Country Seeder",
        )

        for item in countries:

            result = await self.db.execute(
                select(Country).where(
                    Country.iso2 == item["iso2"],
                )
            )

            if result.scalar_one_or_none():
                report.skip()
                continue

            country = Country(
                name=item["name"],
                iso2=item["iso2"],
                iso3=item["iso3"],
                phone_code=item["phone_code"],
                currency_code=item["currency_code"],
                currency_name=item["currency_name"],
                capital=item["capital"],
                continent=item["continent"],
                timezone=item["timezone"],
                flag_url=item.get("flag_url"),
                latitude=item.get("latitude"),
                longitude=item.get("longitude"),
                is_active=True,
            )

            self.db.add(country)

            report.success()

        await self.db.commit()

        report.print()