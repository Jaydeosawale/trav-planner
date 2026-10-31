# Trav: whole-app experience review and next development plan

31 October 2026 · Baseline: build 36, source 14fae3e56029a5451f51c85e111dfd8f50ae3a2c.

The product direction is a connected travel journey: discover an idea, understand how to reach it, see a useful budget and itinerary, refine it, save it, and continue using it during the trip. The first useful plan should arrive before optional questions.

## What was checked

Reviewed official product/help material for Wanderlog, Rome2Rio, Mindtrip, Tripadvisor, Airbnb, Skyscanner and Booking.com. Reviewed Trav’s current routing, Home, Explore, Nearby, place details, AI chat/structured planner, trip editor/details, Saved, Profile, location memory and provider tools. Generated current screen renders at mobile/tablet/desktop widths using 15 passing visual/navigation checks, alongside the existing 101-test baseline.

Screen renders use controlled fixtures. Their example inventory, images, account state and counts are not evidence of live production coverage. This review does not claim hands-on testing of competitors’ authenticated or paid features. Competitor observations are from their official materials; the Trav recommendations below are product/design judgments.

## Patterns worth adapting

| Reference | Observed pattern | Application to Trav |
|---|---|---|
| [Wanderlog](https://wanderlog.com/) | Itinerary, map, reservations and budget belong to one trip workspace. | A saved plan should open a usable trip, with Plan, Map and Budget views sharing the same data. |
| [Rome2Rio](https://www.rome2rio.com/blog/2025/12/02/how-to-use-rome2rio/) | Start with origin/destination; compare transport options, then follow an operator or partner booking link. | Add a “Getting there” summary before daily sightseeing. Keep supplier checkout and payment clear. |
| [Mindtrip](https://resources.mindtrip.ai/travelers/help/traveler-faqs) | Conversation connects to visual places, maps and editable itineraries. | Chat should produce tappable place and journey cards, not only prose. |
| [Tripadvisor AI](https://www.tripadvisor.com/AIAssistant) | Recommendations connect to real place data, visual comparison, editable trips and provider links. | Ground place cards in records with IDs, coordinates and photo sources. Never invent reviews or availability. |
| [Airbnb search](https://www.airbnb.com/help/article/252) | Search, maps, flexible dates and progressively applied filters support discovery. | Let people browse before completing a form; put less-used constraints in one filter sheet. |
| [Skyscanner Everywhere](https://www.skyscanner.net/flights/advice/skyscanner-everywhere-search-how-to-find-flights-to-anywhere-in-the-world) | An origin can lead to destination inspiration when users are undecided. | Offer “Ideas from your area” and reachable weekend suggestions without requiring a destination first. |
| [Booking.com’s documented 2023 planner](https://news.booking.com/bookingcom-launches-new-ai-trip-planner-to-enhance-travel-planning-experience/) | Conversational refinement connects to visual options and booking deep links. | Use quick refinement actions that update the existing draft. This historical example is not a claim of universal current availability. |

## Main findings in Trav

1. **Starting location and browsing area need separate meanings.** `chosenPlaceAreaProvider` represents the area being explored. Looking at Goa must not silently make Goa the trip’s departure point. A saved GPS area is also a saved snapshot, not proof of the user’s present position.
2. **The normal chat result is still principally Markdown.** `AISearchPage._ResponseCard` renders the answer as text. The illustrated structured itinerary exists in a separate planner flow. The visual result and the conversation should share one draft model.
3. **Chat-to-trip saving loses structure.** `_reviewPlan` opens `TripEditorPage` with `draftNotes` containing the AI answer. That does not directly turn the answer’s days and places into itinerary items. This can require another form and additional work from the user.
4. **Worldwide defaults need correction.** `StructuredPlanPage` initializes its currency to INR and dates to today plus two days. Flexible draft duration must not be presented as confirmed travel dates, and INR must not be the universal currency.
5. **Explore has too much setup above results.** The current card-view render stacks a search, introductory heading, categories, country/photo filters, a separate clear-country action and a view toggle before the first place.
6. **Utility screens spend too much space introducing themselves.** Saved places and My Trips repeat large marketing headings. My Trips renders pagination even in an empty/single-page state.
7. **The booking screen provides supplier entry points, not a live fare comparison engine.** Its presentation must preserve that distinction while gaining route context.
8. **Road routing does not supply train or flight schedules.** The current `MapRoutingTool` uses an OSRM driving endpoint. A road duration cannot be reused as a public-bus timetable, railway journey or flight duration.
9. **Home can be more useful without repeating Explore.** Its empty inspiration section and another town-search prompt compete with the hero search. The large approved hero can stay; lower content should adapt to whether a location, draft or upcoming trip exists.

## Recommended AI conversation

### First response

Use known, explicitly supplied information immediately. Separate:

- Starting point: a town the user says they depart from, or a shared GPS area used with a visible assumption.
- Destination: the place they want to visit.
- Browsing area: the context for discovering places; it is not automatically the starting point.

For “Plan Goa” with a known starting point, deliver a compact draft:

1. **Journey header:** starting area → destination, duration, travelers and flexible/specified dates.
2. **Getting there:** relevant road, bus, train or flight choices with evidence-backed estimates or clear supplier-check actions.
3. **Budget preview:** getting there, stay, food, local transport and activities. Show a range only when a defensible basis exists.
4. **Day plan:** short morning/afternoon/evening blocks with real place cards and realistic travel/rest time.
5. **Assumptions:** one compact editable line.
6. **Optional refinement:** “Share your dates, budget or who’s coming and I’ll tailor this more closely.”

Useful defaults: a relaxed three-day draft, one adult, moderate spending and flexible dates. “Today”, “tomorrow” or “a day out” means one day. User-provided values always win. Use an appropriate verified currency or explicit user preference; do not infer nationality from location.

Do not assume an unknown departure town. If it is missing, still provide the destination itinerary and state: “Add your starting town to compare ways to get there.” A short origin question is appropriate when the user specifically asks for a route or journey cost. Ask about an ambiguous destination before choosing the wrong place.

For someone undecided, offer up to three destination ideas using their stated interests, saved starting area and realistic reachability. Do not start a budget/date/traveler questionnaire.

### Refinement

Use small actions such as Lower budget, Less walking, Family-friendly and Change dates. Apply them to the current draft; preserve its selected places and confirmed facts. Show what changed rather than repeating an entire introduction. Optional refinements should never be presented as compulsory steps before the first plan.

Keep the existing five completed AI plans per account per day. Reopening, saving, changing a display filter or rearranging known stops should not itself call an AI provider. Any change to how AI-generated revisions consume the daily quota needs an explicit product decision.

## Screen-by-screen changes

| Screen | Main purpose and first useful content | Specific changes |
|---|---|---|
| Home | Start or continue an adventure. | Preserve the approved large rotating photo banner, bottom town search and centered dots. Below it, show Continue planning/Upcoming trip when available, a short nearby rail, destination inspiration and the day cards. Hide empty rails instead of allocating large blank sections. Keep Nearby, Book and Saved as shortcuts. |
| Explore | Find a particular place or browse an area. | One unified town/place search, a compact category row and one Filters action. Move photo-only/country/extra constraints into that sheet; represent active constraints as removable chips. Bring result count and the first result higher. Preserve query, filters and scroll position on return from details. |
| Town suggestions | Resolve a small or ambiguous location. | Show town, region and country together. Distinguish a destination from a venue result. Select the exact record once; do not require country → state → city drilling. Retain useful matches when one free source is unavailable. |
| Nearby | Find useful places around the chosen area. | Retain the new compact build-36 pattern. Add consistent photo/icon rows and clear empty states. Keep saved-area context visible with Change; never show the old settings instructions after success. Treat saved GPS as an area snapshot, with refresh available. |
| Destination overview | Decide whether to visit and start planning. | Destination image, short introduction, key attractions, category rails and one primary Plan this trip action. Put Getting there and rough budget context here when origin/data exist. A destination region and its starting town must be labelled accurately. |
| Place details | Understand one place and act. | Photo, name, category, location and a short description first. Prioritize Directions for someone already nearby, or Add to plan when editing a trip. Keep Save as a compact secondary action. Group address, known hours, website and source details below. Do not invent missing hours, ratings or ticket prices. |
| AI Planner | Create and refine the trip. | Keep the clean composer. Add compact starting-point/destination context, a visual draft with Getting there/Budget/Days, and optional refinement chips. Avoid giant paragraphs and another mandatory form after the answer. |
| Getting there / Book | Compare the journey and reach the supplier. | Carry origin, destination, dates and travelers from the trip. Show relevant modes, transfers and estimate/source status. Search flights or trains directly without requiring AI. Label the external action Continue on supplier site; do not imply payment or reservation was completed inside Trav. |
| Trip workspace | Use the saved plan. | One trip header and Plan, Map, Budget views. Connect a day’s stops to the map, allow moving/removing/replacing stops, and keep notes/bookings together. A supplier click is not a confirmed booking. |
| My Trips | Resume a draft or upcoming trip. | Compact Draft/Upcoming/Past organization, useful trip cards and a single New trip action. Hide pagination on empty/single-page lists. Keep the empty state brief with one clear action. |
| Saved places | Turn interest into a plan. | Compact heading, search and optional destination collections. Allow selecting saved places to add to an existing draft. Use human-readable category labels and a brief empty state. |
| Profile / preferences | Manage identity and explicit preferences. | Keep Profile behind the avatar, outside bottom navigation. Group account, travel preferences, saved starting area/location controls, privacy and help. Explain personalization with “Because you saved…” rather than inferring mood or personal traits invisibly. |
| Sign-in / recovery | Complete authentication with minimal interruption. | Keep full-screen auth without bottom tabs. Preserve the intended destination/action and entered draft when returning. Use clear loading, error and recovery success states. Guest browsing remains useful; signed-in AI retains its limit. |
| Admin | Maintain trustworthy coverage and service limits. | Separate content quality from AI/provider controls. Add/retain duplicate checks, coordinate/category validation, image credits and pending/published place states. Surface coverage gaps, failed searches, quota/reset status and routing failures. Provider switching must respect configured keys, audit records and the zero-spend policy. |

## Navigation and visual system

Retain four main tabs: Home, Explore, AI Planner and My Trips. Keep Saved accessible from Home/Profile and booking accessible from Home and within a trip. Contextual screens open from these destinations; a new bottom tab is not needed for every feature.

Keep the current ocean blue, teal and sunset accent identity. The next improvement is hierarchy and consistency: one primary action per screen, fewer large introductory headings on utility pages, consistent spacing, clear title/body/secondary text roles, stable image ratios and meaningful empty states. Preserve the requested complete-photo treatment and original banner design. Avoid adding blur to every surface.

Mobile uses a compact list/map switch and a detail sheet. Wider layouts can put the itinerary/results beside the map. Keyboard focus, accessible labels, text scaling, readable contrast and loading/error/empty states are part of each component, not a later styling pass.

## Honest journey and budget estimates

Use three visibly different states: supplier-checked information, a labelled planning estimate with assumptions, and unavailable information with a supplier-check action. Unknown is never zero.

- Road distance/time: measured route data when the routing request succeeds; it is not live traffic or a ticket timetable.
- Train, public bus and flights: verified schedule/fare data only when a suitable source is connected. Otherwise offer operator/search links with the known origin and destination.
- Private vehicle cost: calculate from a measured distance and visible assumptions for fuel consumption/price; distinguish one-way/return, tolls, parking and rental cost. Do not silently include all of these in one invented amount.
- Stay/food/activity budgets: use reviewed, dated regional ranges or explicitly labelled planning allowances. Separate per-person costs from shared room/car costs. Show what the total includes.
- Final checkout: supplier decides availability and the payable price. [Rome2Rio’s pricing explanation](https://help.rome2rio.com/en/support/solutions/articles/22000239374-how-do-you-determine-your-prices-) illustrates why different modes require different underlying estimate data.

## What is feasible at zero platform cost

Keep existing open-place data, on-demand retrieval, licensed photos and bounded caches. Do not try to preload every world place or run parallel agents for every suggestion.

[Geoapify’s Free plan](https://www.geoapify.com/pricing/) allows commercial production within its 3,000-credit daily quota and required attribution. This is credits, not a guarantee of 3,000 arbitrary complex routes: [routing costs](https://apidocs.geoapify.com/docs/routing/routing/) vary by waypoints, distance and options. Account for shared places/routing usage and enforce the free ceiling before calling.

The current [OSRM public server policy](https://github.com/Project-OSRM/osrm-backend/wiki/Api-usage-policy) points to the [routing service conditions](https://routing.openstreetmap.de/about.html). These shared public services have usage restrictions and best-effort availability; do not treat a demo endpoint as an unlimited worldwide production backbone. Prefer the existing production-allowed free provider within its shared budget, cache non-personal route results appropriately, and retain external map/operator links when unavailable.

No connected free service in Trav currently provides guaranteed live worldwide flight, train and public-bus fares plus bookable inventory. We can deliver a useful planning and supplier-handoff experience at zero subscription cost within free quotas, with honest estimates and coverage limits. We cannot promise unlimited global data, live prices or availability on that basis.

## Development order

1. **Shared trip context and visual AI draft.** Separate origin/destination/browsing area, reuse known facts, label assumptions and connect structured output to the normal chat. Keep a fallback readable response if structured output is invalid.
2. **Save and reopen that same draft.** Reuse the existing structured itinerary schema and day/place IDs. Save a complete draft instead of copying an answer into notes and asking users to rebuild it. Support flexible dates without inventing confirmed dates.
3. **Getting there and budget.** Add verified road context, defensible calculation inputs and operator links. Keep train/flight availability unknown unless actually checked. Keep all calls within the existing free-only policy.
4. **Unified trip workspace.** Plan/map/budget views, place additions from Explore/Saved, local reorder and return-to-trip behavior.
5. **Consistent discovery and utility screens.** Simplify Explore, shorten My Trips/Saved headers, improve Home’s state-aware rails and place detail action priority.
6. **Quality and operational controls.** Data/photo matching, unknown/missing-data recovery, admin coverage tools, offline saved summaries and optional sharing. Introduce collaboration/reservation imports only after the core single-user flow is reliable.

The logical workflow can be context resolution → place/route retrieval → deterministic cost calculation → itinerary composition → validation → presentation. These do not need to be separate paid AI calls. Use one coordinated planner with bounded tools, preserve the current free-credit restrictions and avoid background generation.

## Acceptance checks for the first development pass

- “Goa for two days” gives a useful first draft without asking for every optional field.
- A known starting area is shown separately and can be changed; a browsing destination is never silently substituted for the origin.
- With no origin, the destination draft still works; journey comparison asks for a starting point only when needed.
- Ambiguous towns are resolved using region/country, not an arbitrary first match.
- Optional dates/travelers/budget refine the current draft; no repeated questionnaire.
- Failed route/fare lookup produces no fabricated “cheapest” badge, zero fare or guaranteed departure.
- A displayed total matches its included per-person/shared-cost assumptions and currency.
- Save/reopen preserves the actual days, place IDs, edits, origin and assumptions without retyping the chat.
- Returning from place details restores Explore’s filters and scroll position.
- Guest, signed-in traveler and administrator flows remain separate; location and drafts remain account-isolated.
- Mobile widths and large text remain usable. Confirm store-facing behavior on the phone before a later release.

## Store state

The user explicitly deferred release on 31 October 2026. Build 36’s signed production bundle is prepared and verified, but this research does not submit or publish it. The new recommendations are a development blueprint, not claims that these features already exist in the installed app.
