# Trav Data Safety mapping — 20 October 2026

Source-reviewed: Flutter normal-user flows, FastAPI auth/user/trips/AI/discovery APIs,
providers and server logging. No Firebase, advertising or analytics SDK was found.

- Name, email, account ID and other personal information (password credentials and
  trip preferences) are collected. Account data is optional because users can browse
  without signing in. Passwords are stored hashed, not as plaintext.
- Optional approximate/precise foreground location supports Nearby. No background
  location is requested. Coordinates are passed to discovery services; disclose
  collection and sharing conservatively rather than assert every provider qualifies
  for the service-provider exemption. Do not claim ephemeral handling where caching
  or provider logging may retain information.
- AI conversations are Other in-app messages. Trips, itineraries and content-report
  text are Other user-generated content. Optional preference/context information may
  reach the configured AI provider. These types are declared collected and shared:
  do not assume Gemini free-tier content is processed only on the developer's behalf.
- App interactions include stored place views/likes/saves; in-app search history is
  separately declared. Their use is functionality/personalisation, not advertising.
- Technical diagnostics/request logs are required for service operation and security.
  No explicit persistent device/advertising identifier collection was found in normal
  app code. Mere presence of device_info_plus is not proof it is called.
- No inbox/SMS access, health/finance access, contact import, gallery upload or
  microphone feature is used by normal accounts. Do not inherit MessageShield's SDK
  or SMS/image-analysis declarations.
- Email/password only. No Google/Apple OAuth option is configured in this release.
- HTTPS transport. Account and individual-data deletion can be requested through
  the public Trav deletion page; follow operations.md, including hard deletion and
  ownership verification. No MASA, UPI or Families badge is claimed.

Reference: https://support.google.com/googleplay/android-developer/answer/10787469
Review the generated Console preview before saving the imported CSV.

Gemini unpaid-service terms permit model/product improvement and human review. AI-sharing purposes include functionality and analytics for this provider use. Terms: https://ai.google.dev/gemini-api/terms . Initial countries must satisfy the provider region restrictions; EEA/UK/Switzerland require paid service.
