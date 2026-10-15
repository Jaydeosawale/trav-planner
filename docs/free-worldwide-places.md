# Worldwide places on a free budget

Trav queries one destination area on demand, rather than downloading the world.
Existing GeoNames destination lookup, Wikidata attractions, Wikimedia photo
credits, admin-authored places, and licensed regional OSM packs remain supported.
The public Overpass source has returned HTTP 500 in production; it is not a
reliability guarantee.

## Optional Geoapify Free project

Verified on 15 October 2026: the dedicated Trav project is Free ($0/month),
3,000 credits/day, up to five requests/second. No paid plan is enabled by code.
Keep the project dedicated to Trav; changing its plan requires a separate review.

Private backend environment settings:

- `GEOAPIFY_API_KEY`: the dedicated project's secret key, never in GitHub or Flutter.
- `GEOAPIFY_FREE_PLAN_CONFIRMED=true`: set only after checking the free plan and
  deploying the frontend attribution links.

The adapter uses POST with the key in a header, a public city centre, a fixed
category list, a five-kilometre radius and at most 20 results per request. It
shares Trav's existing atomic 200-source-requests/day budget across all users.
The administrator can lower or pause this budget. Every request reserves budget,
even if the source fails. There is no automatic pagination, paid fallback,
account rotation or retry to evade quota. HTTP 429 triggers source cooldown.
Results are cached; the cache remains bounded at 2,500 rows / 12 MiB and external
discovery stops at the existing database safety limit. This is a bounded service,
not an unlimited catalogue. Candidate cache expiry does not delete published or
saved Place records.

Geoapify supplies mapped places; it does not guarantee every business, live
opening status, photos, prices, tickets or availability. Returned names,
coordinates and categories are validated, IDs deduplicated, and existing admin
hidden/edited records respected. Source retrieval date and attribution are kept.
Source-supplied image URLs are not fetched automatically. Where available,
Wikimedia images retain their licence/author information. No generated picture
is presented as a photo of a real place.

The phone/web interface displays linked Geoapify and OSM attribution when these
results are used. Public city centres only are transmitted by this adapter—not
precise user GPS, conversation text, email addresses or trip history.

## Google Places decision

Useful as a separate user-directed Google Maps handoff. Its API requires billing,
has field/SKU-specific allowances and paid overages, restricts caching, and
requires Google Maps when its results are displayed on a map. Do not mix its
content into the current OSM cache/map or scrape Google Maps. No Google Places
API credentials or billable service are enabled by this release.

## Validation before calling the connection live

Run the backend CI suite including test_geoapify, the Flutter suite and analysis.
After deployment and private configuration, check Pune plus geographically
separate large/small destinations through the authenticated Trav API. Verify
source credit, sensible distance, repeated-search cache behavior and quota caps.
Do not label the connection live based solely on mocked tests.

Sources:
- https://www.geoapify.com/pricing/
- https://apidocs.geoapify.com/docs/places/
- https://developers.google.com/maps/documentation/places/web-service/usage-and-billing
- https://developers.google.com/maps/documentation/places/web-service/policies
