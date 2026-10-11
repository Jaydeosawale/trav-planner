"""Build a bounded, reproducible GeoNames snapshot from downloaded extracts."""
import gzip
import hashlib
import io
import json
import math
import sys
import zipfile
from pathlib import Path

CONTINENTS = dict(AF='Africa', AS='Asia', EU='Europe', NA='North America', OC='Oceania', SA='South America', AN='Antarctica')


def build(source: Path) -> dict:
    countries = {}
    for line in (source / 'countryInfo.txt').read_text().splitlines():
        if not line or line.startswith('#'):
            continue
        f = line.split('\t')
        if f[0] in {'AN', 'CS'}:  # dissolved territories in the source notes
            continue
        countries[f[0]] = dict(iso2=f[0], iso3=f[1], name=f[4], capital=f[5],
            continent=CONTINENTS[f[8]], currency_code=f[10], currency_name=f[11],
            phone_code=f[12] if len(f[12]) <= 10 else '', timezone='Not available')
    regions = {}
    for line in (source / 'admin1CodesASCII.txt').read_text().splitlines():
        f = line.split('\t')
        regions[f[0]] = f[1]
    cities = []
    with zipfile.ZipFile(source / 'cities15000.zip') as archive:
        for line in io.TextIOWrapper(archive.open('cities15000.txt'), encoding='utf-8'):
            f = line.rstrip('\n').split('\t')
            if f[8] not in countries or len(f[1]) > 150:
                continue
            lat, lon = float(f[4]), float(f[5])
            if not math.isfinite(lat + lon) or not (-90 <= lat <= 90 and -180 <= lon <= 180):
                raise ValueError('Invalid source coordinates')
            key = f'{f[8]}.{f[10] or "00"}'
            cities.append(dict(id=f[0], name=f[1], country=f[8], region=key,
                region_name=regions.get(key, 'Unspecified region'), latitude=lat, longitude=lon,
                population=int(f[14]), timezone=f[17], modified=f[18]))
    # Largest city provides an example zone, never an assertion of one country-wide zone.
    for city in sorted(cities, key=lambda c: c['population']):
        countries[city['country']]['timezone'] = city['timezone'] or 'Not available'
    return dict(provider='GeoNames', license='CC-BY-4.0', retrieved_on='2026-10-11',
        source='https://download.geonames.org/export/dump/',
        source_sha256={name: hashlib.sha256((source / name).read_bytes()).hexdigest()
            for name in ['countryInfo.txt', 'admin1CodesASCII.txt', 'cities15000.zip']},
        countries=list(countries.values()), cities=sorted(cities, key=lambda c: int(c['id'])))


if __name__ == '__main__':
    data = build(Path(sys.argv[1]))
    output = Path(__file__).parent / 'data' / 'geonames_major_cities.json.gz'
    with output.open('wb') as file:
        with gzip.GzipFile(fileobj=file, mode='wb', mtime=0) as compressed:
            compressed.write(json.dumps(data, ensure_ascii=False, separators=(',', ':')).encode())
    print(f"Snapshot: {len(data['countries'])} countries/territories, {len(data['cities'])} cities; {output.stat().st_size} bytes")
