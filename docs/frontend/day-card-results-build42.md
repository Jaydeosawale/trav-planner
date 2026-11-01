# Day-card results and a clean Home — build 42

1 November 2026.

When Explore was reused for a Home day card, didUpdateWidget changed the city/category but cleared local results without starting discovery. Returning to a previously loaded category also discarded its cached results while the already-discovered flag prevented a replacement request. The updated screen restores the matching cache and schedules discovery for a new route/category. Microtask scheduling avoids relying on an additional unrelated rendered frame.

The empty state is suppressed while local discovery is active. Local results have a correct loaded count rather than a contradictory zero-catalogue count. Provider credits are consolidated into one Explore footer covering both catalogue and additional records.

Home no longer fetches Geoapify discovery for its curated rail or displays Geoapify/OpenStreetMap-derived previews. Its independent/admin destination previews and day cards remain. Source-derived listings remain available in Explore and details with visible credits, as required by the free service: https://www.geoapify.com/pricing/ . This allows the requested credit-free Home without hiding attribution beside results that require it.

Minimal validation: one reused-Explore regression covers loading cafés, waiting without a premature empty state, changing category and restoring cached cafés without another request. One Home check covers credit-free previews. One existing Home navigation check confirms that a day card carries its town/category. All three focused tests passed; the full suite was not run.
