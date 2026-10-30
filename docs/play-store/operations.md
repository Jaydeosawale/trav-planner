# Trav Play release operations

App: Trav · com.jaydeo.travplanner · free
Console app ID: 4972372695843640924
Internal track: 4701587607702177977
Production track: 4697294356896467671
First production availability: India only (user-approved).
Gemini free-tier region restrictions: https://ai.google.dev/gemini-api/terms
Public privacy: https://jaydeo-sawale-portfolio.vercel.app/trav/privacy/
Public deletion: https://jaydeo-sawale-portfolio.vercel.app/trav/delete-account/
Support: jaydeep.sawale97@gmail.com

## Account deletion requests

Monitor the support mailbox and complete verified requests normally within 30 days.
Never ask for a password. Confirm ownership through the registered email address.
Prepare a transaction and record the affected account ID and row counts in a private
support record. Do not execute deletion until the account owner has requested it.

Remove child records before parents, including soft-deleted rows:
- itinerary_items for the account's itinerary_days/trips, then itinerary_days;
- any booking records associated with the account/trips, if deployed;
- trips and then planners owned by the account;
- user_place_saves, user_place_likes, user_place_views, user_search_history,
  user_travel_profiles, planner_conversations, ai_itinerary_drafts,
  ai_content_reports, password_reset_tokens, and ai_usage_records linked to the user;
- remove identifying references in admin routing/billing/audit records if applicable;
- users last, after confirming all current foreign keys and user_id columns have been
  checked against the deployed schema. Abort rather than partially delete on error.

Use physical deletes, not only is_deleted flags. Verify zero remaining account-linked
personal rows before committing; rollback on any mismatch. Rotate/invalidate tokens
by removing the account. Do not remove the shared countries/cities/place catalogue.
Reply to the requester after completion, noting any legally required exception and
provider-managed backup rotation. Do not claim third-party logs were immediately erased.

## AI content report review

Authenticated users submit reports inside the app through POST /api/v1/ai/content-reports.
An administrator can list the newest 100 reports with GET at the same path and update
review status with PATCH /api/v1/ai/content-reports/{id}, body status set to reviewed,
actioned or dismissed. Normal users cannot list or change reports. The API stores a
bounded generated-answer snapshot rather than the full chat for chat reports.
Review new reports regularly and before each release. Investigate harmful examples,
update provider safety instructions/filters and regression cases as appropriate,
record the action and mark its status. Review does not itself modify AI filters.
Never expose reporter information or report contents publicly.

## Release checks

Do not submit the Android bundle until the migration and reporting endpoint are live.
Verify account login, guest discovery, AI planning, saving and reporting against the
production backend. Use only a dedicated normal reviewer account in Play Console.
Privacy/deletion pages must remain reachable without login. Record build hashes and
Google's final validation results. App creation is not publication.


## Update submitted — 29 October 2026

Trav 1.0.22 / versionCode23 was uploaded as the signed all-architecture bundle and accepted by production validation. Production release2 is submitted for review; the publishing page shows Changes in review while Google quick checks run. Managed publishing remains off and rollout is100% within existing country targeting (India). Public version1.0.21 remains live until Google publishes the update.

Verification in this submission: source commitc3f675e, valid bundle signature, all3 native architectures, no lost device support according to Play, health/privacy/deletion URLsHTTP200 and protected reporting endpointHTTP401 without credentials. Automated app/backend regressions and live public discovery were checked in the build task. Fresh private-account AI generation and administrator-report review were not repeated in the submission turn. No review credentials or API keys were changed or exposed.

## In-app updates (1.0.23 / build 24)

Google Play Android installs check for eligible flexible updates at startup and
resume, at most once every five minutes. Trav offers Update once per available
version per app session. Play handles consent and background download; Trav then
offers Restart without forcing it. Downloaded updates are recovered on next
startup/resume. Offline checks and sideloaded APKs never block browsing.
No new backend, paid service, credentials or Android permissions are required.

Implementation: `frontend/lib/core/updates/app_update_prompt.dart`, connected by
`frontend/lib/main.dart`, using `in_app_update` 5.0.0. Versions remain in
`frontend/pubspec.yaml`; Android Gradle reads them automatically.

Local channel-mocked tests cover consent before download/restart, downloaded
update recovery, no update, unsupported platforms and Play errors. Real end-to-end
verification requires an older Play-installed version containing this feature
and a higher version available to the same account, with matching package/signing.
The prompt helps with releases after 1.0.23; older versions lack the feature.
See https://developer.android.com/guide/playcore/in-app-updates/test.
