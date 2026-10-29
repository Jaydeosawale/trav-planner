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

## 1.0.22 — connected discovery and planning (29 October 2026)

The app now uses a state-preserving routed shell for Home, Explore, Planner, Trips and Profile. Search/filter choices can be restored from `/explore` query parameters, and published places have `/places/:id` loaders. Trips use an authenticated link route. Existing password-reset fragments, the web Play Store banner, privacy links and AI content reporting are retained. Unknown, expired or unavailable links offer a recovery action.

Home has a compact Ocean Escape layout and an independent search field. Location lookup merges stored cities with the existing locally hosted settlement index, keeping regional/country labels. Selecting an area scopes the catalogue, and additional source discovery requires an explicit action. Guests can browse published data and search location names; resolving a new location, saving or generating a plan prompts sign-in and resumes the action. No new paid provider or external per-keystroke POI request is introduced.

Home, Nearby and Saved share a place-detail presentation. Place cards link to that route, Directions uses a destination directions URL, and Add to trip offers an existing day or a new trip. Source candidates are resolved before an itinerary item is written. The picker checks the latest day for duplicates and keeps the source place ID. Trip creation can resume after sign-in without discarding form values.

The AI composer stays anchored, and the intro collapses during a conversation. Exact brief dates, budget/currency and party size are copied into daily-plan review; uncertain natural-language values remain visible context. Selected-place IDs are included in generation, checked against the selected destination and validated in the returned plan. A missing required place rejects the draft rather than silently substituting it. Existing free-provider controls and AI content reports remain active.

Session recovery now distinguishes invalid credentials from connectivity/server errors, shares one refresh across concurrent requests and limits original-request retries. Nearby checks visible cache entries against the actual requested distance, chooses the nearest known source city and explicitly describes partial city-centre coverage. Map results can be recentered; changed areas refit the viewport without continually overriding deliberate panning.

Validation: 67 Flutter tests and 64 backend tests passed after integrating the latest Play-release changes. Additional final routing/trip checks passed. Analysis has no errors or warnings; existing informational lints remain. Mobile renders include 360×800 and 200% text checks. No database migration was added for these features.

Remaining scope: free sources still do not cover every locality/business or live availability. Nearby external discovery remains centred on known public towns and can cover less than a user's selected radius. Existing generic catalogue classifications need editorial review; new Wikidata retrieval retains source-specific park/museum categories. Broad local-script alias expansion, offline trip packs and advanced personalised recommendations remain future work. Publishing a new Play Store release is separate from preparing an Android artifact.

Latest Home adjustment: the destination banner is larger (minimum 260px on phones, 340px on wide screens). Area selection lives in the mobile/tablet header and desktop navigation. Town/place search is embedded in the banner, with focus stopping the timer. The slider keeps dots only. Layout tests confirm search lies inside the banner, the area control sits above it, narrow/200%-text layouts fit, and the first place name remains visible at 360×800. The Sights catalogue filter also accepts existing landmark/monument records so stored iconic sights are not hidden by legacy type labels.
