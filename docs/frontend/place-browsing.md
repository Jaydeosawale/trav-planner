# Place browsing — 1.0.21

Home starts with the existing timed destination spotlight (dots only), then Nearby, Book and Saved shortcuts. A photographed place feed follows, with visible category chips and country/photo controls. Destination browsing and the AI planner remain separate actions below it.

Explore now opens Discover places. Users can scroll cards without typing, search a place/city/interest, select a category or country, include or exclude records without a photo, and switch between cards and a map. Pagination loads 20 records at a time; changing filters resets pagination and the map. Home’s See all action carries its selection into Discover.

A place opens its own detail screen: photo and attribution, category/city, description/address when available, save, directions and map when coordinates exist, then Plan a visit. Planning pre-fills the conversational planner and does not send an AI request automatically. Destination browsing and Nearby remain the entry points for additional on-demand local discovery.

## Data and cost

The feed reads the published catalogue; scrolling does not call Geoapify or an AI provider. Existing free discovery quotas and storage limits are unchanged. The public search endpoint supports has_photo and includes city_name/country_id. Inactive parent locations are excluded, and country/state filters apply equally to results and pagination counts. No migration is needed.

Photos are actual record images. Missing or failed images have a labelled fallback; unrelated destination photographs are not assigned to individual places. Wikimedia thumb-host URLs are delivered through Wikimedia’s upload CDN with the file path preserved; attribution remains visible. The photo filter checks that a record has an HTTP(S) image URL, not a guarantee that the external image service is available.

The live catalogue checked before deployment had 16 places, 12 photo links and seven destinations without cover photos. The feed is not a complete worldwide database; destination and nearby discovery retrieve more records within the existing free limits. No ratings, opening hours, prices or confirmed tickets are fabricated.

## Verification

Backend suite: 58 passing tests. Flutter: 49 existing/product tests passed; final four focused tests include image CDN normalisation, category/country/photo propagation, map switching, details-to-AI navigation and narrow Home rendering. CI runs the full suite on push. Rendered previews use explicitly labelled Paris UI fixtures, not production POI claims.
