# Home discovery and attribution — build 39

1 November 2026.

Home now merges published catalogue records and local-source results into one horizontal inspiration rail, deduplicated by place ID. It shows up to eight cards and one source-credit group; See all opens full discovery. This removes separate catalogue/local rows for a selected town such as Pune. The full Explore catalogue keeps its existing vertical/grid layout.

What kind of day cards have illustrated color badges: gradient backgrounds, larger category icons and small contrasting details (a green leaf for coffee, sun for scenery/parks/coasts, warmth for food, sparkle for culture). Category navigation and the selected town are preserved.

Geoapify and OpenStreetMap credits use 11px secondary text with compact padding and left-aligned wrapping links. Required names and fixed attribution links remain present. Standalone destination/Nearby OSM credits use the same small text size. Map attribution was already 11px and remains outside the map canvas.

No additional service, source quota, payment change or store publication is introduced. The regression check reproduces overlapping Pune records from the two sources and verifies a single scrollable rail without duplicate entries.

Validation: the 116-test app suite passed, followed by the new Pune rail regression (117 checks total). Analysis has no errors or warnings; 21 existing informational lints remain. Home badges and the one-row Pune fixture were visually inspected at 320px.
