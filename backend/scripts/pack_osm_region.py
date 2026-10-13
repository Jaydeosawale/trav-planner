"""Create reviewed, bounded regional OSM packs locally; never calls Overpass."""

import argparse
import json
from pathlib import Path
from math import radians, sin, cos, asin, sqrt


def kind(tags):
    return (
        {"restaurant": "restaurant", "cafe": "cafe", "parking": "parking"}.get(
            tags.get("amenity")
        )
        or {
            "hotel": "hotel",
            "hostel": "hotel",
            "guest_house": "hotel",
            "museum": "museum",
            "attraction": "attraction",
            "viewpoint": "attraction",
        }.get(tags.get("tourism"))
        or (
            "station"
            if tags.get("railway") == "station"
            else (
                "bus_stop"
                if tags.get("highway") == "bus_stop"
                else (
                    "park"
                    if tags.get("leisure") == "park"
                    else (
                        "beach"
                        if tags.get("natural") == "beach"
                        else (
                            "airport"
                            if tags.get("aeroway") == "aerodrome"
                            else "shop" if tags.get("shop") else None
                        )
                    )
                )
            )
        )
    )


def main():
    import osmium

    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("output_directory")
    parser.add_argument("--city-id", required=True)
    parser.add_argument("--latitude", type=float, required=True)
    parser.add_argument("--longitude", type=float, required=True)
    parser.add_argument("--radius-km", type=float, default=15)
    args = parser.parse_args()
    if not (
        -90 <= args.latitude <= 90
        and -180 <= args.longitude <= 180
        and 0 < args.radius_km <= 40
    ):
        raise SystemExit("Use valid coordinates and radius up to 40 km.")
    if Path(args.input).stat().st_size > 200 * 1024 * 1024:
        raise SystemExit("Choose a regional extract smaller than 200 MB.")

    def nearby(x, y):
        v = (
            sin(radians(x - args.latitude) / 2) ** 2
            + cos(radians(x))
            * cos(radians(args.latitude))
            * sin(radians(y - args.longitude) / 2) ** 2
        )
        return 6371 * 2 * asin(min(1, sqrt(v))) <= args.radius_km

    records = []

    class Handler(osmium.SimpleHandler):
        def add(self, element, x, y, source):
            tags = dict(element.tags)
            category = kind(tags)
            name = tags.get("name")
            if (
                len(records) >= 1000
                or not category
                or not name
                or not (2 <= len(name) <= 200)
                or not nearby(x, y)
            ):
                return
            records.append(
                dict(
                    external_id=f"{source}/{element.id}",
                    name=name,
                    place_type=category,
                    latitude=x,
                    longitude=y,
                    description=(
                        tags.get("description", "")
                        + (
                            " Approximate feature centre, not a confirmed entrance."
                            if source == "way"
                            else ""
                        )
                    )[:1000],
                )
            )

        def node(self, node):
            if node.location.valid():
                self.add(node, node.location.lat, node.location.lon, "node")

        def way(self, way):
            if not kind(dict(way.tags)):
                return
            points = [
                (n.location.lat, n.location.lon)
                for n in way.nodes
                if n.location.valid()
            ]
            if points:
                self.add(
                    way,
                    sum(p[0] for p in points) / len(points),
                    sum(p[1] for p in points) / len(points),
                    "way",
                )

    Handler().apply_file(args.input, locations=True)
    output = Path(args.output_directory)
    output.mkdir(parents=True, exist_ok=True)
    for start in range(0, len(records), 200):
        (output / f"osm-pack-{start//200+1:03}.json").write_text(
            json.dumps(
                {
                    "city_id": args.city_id,
                    "license": "ODbL-1.0",
                    "items": records[start : start + 200],
                },
                ensure_ascii=False,
                indent=2,
            )
        )
    (output / "SOURCE.txt").write_text(
        "Source: OpenStreetMap contributors, ODbL 1.0. https://www.openstreetmap.org/copyright\nRegional extract: "
        + Path(args.input).name
        + "\nReview records before importing/publishing.\n"
    )
    print(f"Prepared {len(records)} source records in bounded review packs.")


if __name__ == "__main__":
    main()
