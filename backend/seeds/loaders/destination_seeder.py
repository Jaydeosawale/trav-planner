"""
Destination Seeder.
"""

from __future__ import annotations

from sqlalchemy import select

from app.modules.destination.model import Destination

from seeds.constants import DataPaths
from seeds.loaders.base import BaseSeeder
from seeds.utils.json_loader import JsonLoader
from seeds.utils.report import SeederReport
from seeds.utils.registry import SeederRegistry


@SeederRegistry.register("destination")
class DestinationSeeder(BaseSeeder):
    """
    Seed destinations into database.
    """

    async def seed(self) -> None:
        """
        Seed destinations.
        """

        loader = JsonLoader()

        destinations = loader.load(
            DataPaths.DESTINATIONS,
        )

        report = SeederReport(
            "Destination Seeder",
        )

        # ======================================================
        # Existing destination lookup
        # ======================================================

        result = await self.db.execute(
            select(Destination)
        )

        destination_lookup = {
            destination.slug: destination
            for destination in result.scalars().all()
        }

        # ======================================================
        # Seed destinations
        # ======================================================

        for item in destinations:

            slug = item["slug"]

            # --------------------------------------------------
            # Duplicate Check
            # --------------------------------------------------

            if slug in destination_lookup:
                report.skip()
                continue

            # --------------------------------------------------
            # Create Destination
            # --------------------------------------------------

            destination = Destination(
                city_id=item["city_id"],
                name=item["name"],
                slug=slug,
                short_description=item.get(
                    "short_description"
                ),
                description=item.get(
                    "description"
                ),
                image_url=item.get(
                    "image_url"
                ),
                latitude=item.get(
                    "latitude"
                ),
                longitude=item.get(
                    "longitude"
                ),
                is_featured=item.get(
                    "is_featured",
                    False,
                ),
                is_active=item.get(
                    "is_active",
                    True,
                ),
            )

            self.db.add(destination)

            destination_lookup[slug] = destination

            report.success()

        await self.db.commit()

        report.print()
