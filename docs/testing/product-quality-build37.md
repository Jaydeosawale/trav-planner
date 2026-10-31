# Trav build 37: product quality and screen review

31 October 2026. Version 1.0.24+37. Google Play release remains on hold at the user's request.

## Scope and changes

| Screen / flow | Change or verification |
| --- | --- |
| Home | Hide an empty curated rail, retain retry on errors; compact shortcuts fit narrow phones without splitting words. Retain approved large hero, full-photo treatment, bottom town search and centered dots. |
| Explore / places | One search, horizontal categories, Filters sheet, compact Map/Cards control; country/photo settings appear as removable active chips. Less setup above the first result. |
| Nearby | Discard old-account and previous-origin results; discard GPS results after account changes. Existing explicit native location permission remains. |
| Destination / place details | Shorter, smaller headings and safe refresh failure handling; existing source attribution and detail actions retained. |
| Saved | Compact introduction and readable category labels. Account isolation and saved-detail navigation covered by regression checks. |
| AI chat | Factual answers cannot be saved as itineraries; plan replies offer optional refinement chips. Saved briefs prefill review. Unknown daily usage is not shown as five remaining. Account changes clear chat state and reject late private replies. Brief/recent-plan/review/delete callbacks guard account changes. |
| Structured AI review | Respect explicit currency; otherwise use available verified city currency. Accept valid three-letter currencies, and label default dates as draft dates. The active-country response now exposes its optional existing currency_code; older records remain valid. |
| My Trips | Hide empty/single-page pagination; scope page counts to account; ignore late old-account page counts; contain refresh failures. Compact introduction and bounded desktop width. |
| Trip editor | Editing destination text clears the previous city selection. Ignore stale city results. Prefill exact known brief dates, travelers, budget and title; require selecting the actual city. |
| Trip details | Collapsible notes/AI prose, primary day plan, direct map shortcut and a dedicated budget action. Supplier links use a destination field when available instead of the arbitrary trip title. |
| Trip budget (new) | Edit total planned amount and currency without repeating trip creation. Validate values, retain failed edits and permit retry. No AI or paid service call. |
| Itinerary / map | Direct map entry and contained refresh failures; existing add/reorder/remove flows retained. |
| Booking links | Smaller heading and clearer supplier checkout copy. No invented live fares, discounts, bookings or payment confirmations. |
| Profile | Bound desktop width; guests see Sign in rather than Logout; preferences require sign-in. Saved area can be changed or forgotten. Forgetting clears queued device memory for that account only. |
| Mobile navigation | Four tabs retained: Home, Explore, AI Planner, My Trips. Larger labels can use two lines. No Profile tab. |
| Sign-in / registration / recovery | Existing root-route, validation, reset and regular/admin authentication regression checks retained. No credential/provider changes. |
| Admin | Existing provider ordering, disabling, saving and error-retry regression checks retained. No paid-provider policy change. |

## Verification and evidence

Automated checks cover navigation, account isolation, saved places, Home location ideas, native-location adapter behavior, catalogue filtering, trip CRUD, itinerary edits, AI brief/review, authentication routes/recovery validation and administrator AI routing. New regression cases cover stale city selection, stale asynchronous account responses, budget validation/retry, unknown usage, guest profile and 200% text budget layout.

Fixture renders are exported for Home at 320/360/768/1280 widths, Explore, place details, Saved, My Trips, AI onboarding, and budget/profile/trip details at 320 and 1280. Renders are controlled UI fixtures, not evidence of live worldwide source coverage or supplier inventory.

Final verification: 116 Flutter tests passed. The final city/currency contract check passed after matching the real backend response. The selected backend suite passed 74 tests (existing deprecation/schema warnings remain). Flutter analysis completed with no errors or warnings; 21 informational style/deprecation lints remain. Whitespace validation passed. Phone installation and artifact checks are recorded separately with the build output.

## Remaining development

Chat-to-trip saving still stores the AI answer as draft notes; it does not automatically create structured days and activities. A shared structured chat draft with real place IDs, map and editable itinerary is the next larger feature. Origin, destination and browsing area must remain distinct. Multimodal journey comparisons need verified source support; driving estimates cannot stand in for rail or flight schedules.

Free source coverage, photos and daily limits remain finite. This release adds no new provider, billing account or paid request. It does not claim every business worldwide, real-time availability, a fresh delivery-email round trip or an authenticated live AI-provider test. Supplier checkout remains on the supplier site.

Research rationale and the fuller screen roadmap are in the dated whole-app review. Store submission is a separate held action.
