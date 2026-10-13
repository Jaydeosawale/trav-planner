# Free-source discovery

Trav loads a bounded set of nearby places for a selected catalogue city. It does
not store a complete world database or guarantee coverage, uptime, opening hours,
prices, menus, ticket stock, or current booking availability.

Wikidata supplies nearby attractions, museums, parks, beaches and heritage data.
Commons supplies optional photos only after licence, attribution and source checks.
OpenStreetMap supplies food, stays, shops and transport through regional packs.
Public Overpass is not used as an unlimited production backend.

The Monaco starter contains 76 source candidates, not reviewed listings. Admins
can review and publish candidates or import more regional JSON packs.

Source requests are authenticated, shared across users and capped at 200 per UTC
day. Admins can pause requests or lower the cap. There is no paid fallback.
The cache is capped at 2,500 entries and 12 MiB of JSON. New enrichment stops at
200 MiB of PostgreSQL database size. This is an application threshold, not a claim
about the hosting account quota. Caches expire and source cooldowns are respected.
PostgreSQL locks serialize request reservations and cache writes. Saved places
and admin edits survive candidate expiration. The AI tool reads stored places
rather than making its own unbounded external discovery requests.

Run the optional regional importer locally, not on Render:

    pip install -r requirements/import.txt
    python scripts/pack_osm_region.py --help

Use a small Geofabrik .osm.pbf, a real Trav city UUID and verified coordinates.
Upload the output through the admin discovery panel. Packs have at most 200
records. Large planet imports are unsupported. Preserve ODbL attribution.

Sources and policies:
- https://www.wikidata.org/wiki/Help:Data_access
- https://www.wikidata.org/wiki/Wikidata:SPARQL_query_service/query_limits
- https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia
- https://www.openstreetmap.org/copyright
- https://download.geofabrik.de/index.html
- https://dev.overpass-api.de/overpass-doc/en/preface/commons.html

Free hosting and source services can impose further limits or change plans.
Paid discovery calls are disabled; unlimited world coverage and permanently free
commercial hosting cannot be promised.
