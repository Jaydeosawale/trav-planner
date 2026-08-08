"""
City Converter.
"""

from __future__ import annotations

from seeds.constants import DataPaths
from seeds.converters.base import BaseConverter


class CityConverter(BaseConverter):
    """
    Convert raw cities dataset into
    application format.
    """

    async def convert(self) -> None:
        """
        Convert cities dataset.
        """

        raw_countries = self.load_data(
            DataPaths.RAW_LOCATION_DATA,
        )

        processed: list[dict] = []

        for country in raw_countries:

            country_iso2 = country["iso2"]

            for state in country.get("states", []):

                state_code = state["iso2"]
                state_name = state["name"]

                for city in state.get("cities", []):

                    processed.append(
                        {
                            "country_iso2": country_iso2,
                            "country_name": country["name"],
                            "state_code": state_code,
                            "state_name": state_name,
                            "name": city["name"],
                            "latitude": (
                                float(city["latitude"])
                                if city.get("latitude")
                                else None
                            ),
                            "longitude": (
                                float(city["longitude"])
                                if city.get("longitude")
                                else None
                            ),
                        }
                    )

        processed.sort(
            key=lambda item: (
                item["country_iso2"],
                item["state_name"],
                item["name"],
            ),
        )

        self.write_data(
            DataPaths.CITIES,
            processed,
        )

        print(
            f"Converted {len(processed)} cities."
        )