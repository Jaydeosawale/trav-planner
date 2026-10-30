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

## 1.0.24 mobile discovery and conversation flow

Home has a clean logo/account header, a large image banner, search immediately
above centered carousel dots, three direct shortcuts and a vertical place feed.
Scroll near the end to fetch another page; See all remains an optional shortcut.
Mobile navigation contains Home, Explore, AI Planner and My Trips. The account
avatar opens sign-in/profile; the existing profile route remains available.

The Home search opens Explore with keyboard focus. Explore keeps one search
field in its app bar, updates town and place results as the user types, and opens
a selected town immediately. Starting a new search leaves the previous town and
country scope. Signed-in users automatically load local sources once per selected
area/category per screen session, using existing free limits and server caching;
photo filtering reuses results. Refresh remains optional below results.

AI Planner starts with two aligned actions. History and advanced tools are in the
app bar; the detailed AI processing/privacy explanation is in About AI. The chat
instructs the existing provider to ask up to two missing details at a time, keep
confirmed context, and confirm before generating a daily plan. A small response
phase marker is removed by the backend and prevents clarification questions from
showing the itinerary save action. Real model behavior still depends on provider
availability and must be reviewed by the traveler.

Authentication audit (30 October): Firebase is not integrated. Email/password
login uses the existing Trav backend; recovery uses its single-use tokens and
private Vercel/Gmail delivery. Live recovery-status reports available; invalid
credentials and reset tokens return 401. Local tests verify reset expiry, single
use and session invalidation. No physical phone or fresh real-account email
round-trip was tested; the user requested code checks only for now.

Release status: 1.0.24 / build 25 is for testing only. The user explicitly
requested no Google Play update on 30 October. Production remains 1.0.23.
A production draft was opened but no 1.0.24 bundle was uploaded or submitted.

## Test build 26: login, Home hub and daily allowance

Login now dismisses native overlays before returning to a routed Home screen.
Sign-in/register/recovery use the root navigator, outside tab navigation. Profile
and admin logout use the canonical sign-in route. Regression tests reproduce the
old regular-user failure and cover regular/admin login and full-screen account
flows.

Home is a short inspiration hub, while Explore owns full search, filters and maps.
The banner search uses 14px text, no arrow and bottom-aligned dots. Home uses a
short photo rail, actual trip continuation/re-discovery, saved-category suggestions
and browsing ideas. Suggestions are hidden while account data reloads. No supplier
discount is invented; the travel card links to comparison/booking destinations.

The old photo-only default hid many businesses. Home now includes places without
photos and merges free-source records for an explicitly selected town. Category
ideas open Explore in the selected town or focus town search if none is chosen.
Coverage is still limited by source data, caches and existing free daily budgets.

AI planning requires sign-in. Migration b91a408c7d20 adds a UTC daily counter shared
by chat plans and structured drafts. Atomic completion claims enforce five saved/
delivered plans per account/day, including concurrent requests. Questions and
failed generations do not consume a plan; deleting a conversation/draft does not
refund it. The UI reads authenticated /ai/plan-usage and response metadata. The
reset is 00:00 UTC. Existing free-provider and $0 billing rules remain unchanged.

This remains a local Trav Test release. Do not submit a Google Play update until
the user explicitly requests publication after testing.

## Test build 27: exact banner spacing

Remove the remaining Choose area control from the wide-screen header. Home's
search retains 14px text and no trailing arrow. The centered indicator row sits
8px below search and 8px above the banner bottom. Targeted layout tests assert
both gaps and absence of Choose area at phone, tablet and desktop widths.
Google Play publication remains disabled by user request; install Trav Test only.

## Build 28: full photos and complete release review

Travel photos in Home, place cards, details, Explore, saved places, flags and admin
previews preserve the entire supplied image with contain fitting. The old banner
zoom is removed. Home gives photography its own frame above the caption/search,
so text no longer covers landmarks. Search still has no arrow; indicators remain
centered, 8px below it and 8px above the banner bottom.

Retained requirements: four mobile tabs (no Profile), avatar access to account,
root-level sign-in/register/recovery, successful-login overlay dismissal, personal
Home versus full Explore, selected-town free-source discovery, conversation-first
AI with two starting actions, history/advanced tools, final-plan review/save,
in-app AI reporting, and five completed plans per signed-in account per UTC day.
Payment remains on supplier sites and existing $0 provider limits are unchanged.

The user authorized Play publication again after installation on the phone. Build
28 must be installed/opened as Trav Test first, then the production package can be
submitted. The separately installed older Trav Play app remains unchanged until
Google approves/distributes the production release.
