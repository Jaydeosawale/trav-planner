"""
Country Converter.
"""

from __future__ import annotations

from seeds.constants import DataPaths
from seeds.converters.base import BaseConverter


class CountryConverter(BaseConverter):
    """
    Convert raw countries dataset into
    application format.
    """

    async def convert(self) -> None:
        """
        Convert countries dataset.
        """

        raw_countries = self.load_data(
            DataPaths.RAW_COUNTRIES,
        )

        processed = []

        for country in raw_countries:

            processed.append(
                {
                    "name": country["name"],
                    "iso2": country["iso2"],
                    "iso3": country["iso3"],
                    "phone_code": country["phonecode"],
                    "currency_code": country["currency"],
                    "currency_name": country["currency_name"],
                    "capital": country["capital"],
                    "continent": country["region"],
                    "timezone": (
                        country["timezones"][0]["zoneName"]
                        if country.get("timezones")
                        else ""
                    ),
                    "flag_url": country.get("emojiU"),
                    "latitude": (
                        float(country["latitude"])
                        if country.get("latitude")
                        else None
                    ),
                    "longitude": (
                        float(country["longitude"])
                        if country.get("longitude")
                        else None
                    ),
                }
            )

        processed.sort(
            key=lambda item: item["name"],
        )

        self.write_data(
            DataPaths.COUNTRIES,
            processed,
        )

        print(
            f"Converted {len(processed)} countries."
        )