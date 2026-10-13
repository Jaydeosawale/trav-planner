"""Build an offline, read-only town index; never bulk-import it into PostgreSQL."""

import argparse
import gzip
import hashlib
import io
import json
import math
import sqlite3
import unicodedata
import zipfile
from datetime import date
from pathlib import Path


def normalize(value):
    return "".join(
        c
        for c in unicodedata.normalize("NFKD", value.casefold())
        if not unicodedata.combining(c)
    ).strip()


def build(source, output):
    regions = dict(
        line.split("\t")[:2]
        for line in (source / "admin1CodesASCII.txt").read_text().splitlines()
    )
    with gzip.open(
        Path(__file__).parent / "data/geonames_major_cities.json.gz", "rt"
    ) as f:
        countries = {r["iso2"]: r["name"] for r in json.load(f)["countries"]}
    raw = output.with_suffix(".sqlite")
    raw.unlink(missing_ok=True)
    db = sqlite3.connect(raw)
    db.executescript(
        "CREATE TABLE locations (id TEXT PRIMARY KEY, name TEXT, country TEXT, country_name TEXT, region TEXT, region_name TEXT, latitude REAL, longitude REAL, population INTEGER); CREATE TABLE names (name TEXT, id TEXT); CREATE TABLE metadata (value TEXT);"
    )
    count = 0
    with zipfile.ZipFile(source / "cities500.zip") as z:
        for line in io.TextIOWrapper(z.open("cities500.txt"), encoding="utf-8"):
            f = line.rstrip("\n").split("\t")
            if len(f) < 19 or f[8] not in countries or not 2 <= len(f[1]) <= 150:
                continue
            lat, lon = float(f[4]), float(f[5])
            if not math.isfinite(lat + lon) or not (
                -90 <= lat <= 90 and -180 <= lon <= 180
            ):
                continue
            region = f'{f[8]}.{f[10] or "00"}'
            db.execute(
                "INSERT INTO locations VALUES (?,?,?,?,?,?,?,?,?)",
                (
                    f[0],
                    f[1],
                    f[8],
                    countries[f[8]],
                    region,
                    regions.get(region, "Unspecified region")[:150],
                    lat,
                    lon,
                    int(f[14]),
                ),
            )
            for name in {normalize(f[1]), normalize(f[2])} - {""}:
                db.execute("INSERT INTO names VALUES (?,?)", (name, f[0]))
            count += 1
            if count > 400000:
                raise ValueError("Location count guard exceeded")
    db.executescript(
        "CREATE INDEX names_search ON names(name, id); CREATE INDEX region_lookup ON locations(region);"
    )
    metadata = dict(
        provider="GeoNames",
        license="CC-BY-4.0",
        retrieved_on=date.today().isoformat(),
        source="https://download.geonames.org/export/dump/cities500.zip",
        records=count,
        sha256=hashlib.sha256((source / "cities500.zip").read_bytes()).hexdigest(),
    )
    db.execute("INSERT INTO metadata VALUES (?)", (json.dumps(metadata),))
    db.commit()
    db.execute("VACUUM")
    db.close()
    if raw.stat().st_size > 64 * 1024 * 1024:
        raise ValueError("Index size guard exceeded")
    with raw.open("rb") as f, output.open("wb") as dest, gzip.GzipFile(
        fileobj=dest, mode="wb", mtime=0
    ) as g:
        while chunk := f.read(1024 * 1024):
            g.write(chunk)
    raw.unlink()
    print(json.dumps({**metadata, "compressed_bytes": output.stat().st_size}))


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("source", type=Path)
    p.add_argument("output", type=Path)
    a = p.parse_args()
    build(a.source, a.output)
