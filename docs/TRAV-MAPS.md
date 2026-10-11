# Destination discovery: step 1

Implemented: destination cards on Home and city cards in Explore open a detail page. It reads active city places through the public API, offers category filters and List/Map views, and shows selected-pin cards, descriptions, addresses, and external directions. Place IDs and coordinates come from the catalogue, not generated sample content. The current first page is capped at 100 places per city; pagination and viewport search are follow-up work.

The public place API wrapper previously mounted planner routes by mistake. It now mounts the existing place module. Anonymous catalogue reads are covered by a regression test.

## Zero-cost services

- Existing Neon database and Render/Vercel deployment plans are retained.
- OpenStreetMap public raster tiles: no payment setup or API key. Native requests identify `com.jaydeo.travplanner`; Flutter Map 8.3.1's built-in cache uses HTTP freshness headers. Browsers use normal browser caching/referrers. Attribution is outside the map canvas so it stays visible. No offline tile download or background bulk fetching.
- External Google Maps directions links: no Google Maps API or billed SDK integration.
- No geocoding, routing, or additional AI provider calls were added.

Public OSM tile hosting is best effort, can restrict heavy usage, and has no uptime guarantee. Reassess a compliant free hosting option as traffic grows. Policy: https://operations.osmfoundation.org/policies/tiles/

## Verification

- Flutter discovery tests: coordinate parsing/bounds/nonfinite values, empty list/map, readable place without coordinates, and category filters.
- Existing auth and responsive branding tests pass alongside discovery tests.
- Backend tests: anonymous place search, correct route mounting, absence of planner writes in the places namespace; existing recovery/deployment tests pass.
- Production web build passes. Analyzer has no errors or warnings; 13 pre-existing informational findings remain elsewhere.
- Live catalogue probe found no destinations. Adding reviewed destination/place records is the next step. Tests use fixtures; no fixture attractions were published to the live database.

## Next steps in order

1. Review and add an initial destination with verified attraction coordinates and suitable photo rights; verify the real pin/card/directions flow on web and Android.
2. Add Save and Add to trip with ownership checks and persistent trip-stop IDs.
3. Add daily trip maps, map-aware pagination, and explicit destination-place associations.
4. Evaluate free routing within its quotas before showing travel-time estimates. Keep unknown visiting details absent rather than inventing ratings, hours, or fees.
