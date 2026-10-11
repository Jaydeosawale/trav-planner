# Worldwide starter catalogue

This is initial coverage, not a complete worldwide attraction database.

| Destination | Country | Initial famous place |
| --- | --- | --- |
| Mumbai | India | Gateway of India |
| Paris | France | Eiffel Tower |
| Tokyo | Japan | Sensō-ji Temple |
| New York City | United States | Statue of Liberty |
| Sydney | Australia | Sydney Opera House |
| Cape Town | South Africa | Table Mountain |
| Rio de Janeiro | Brazil | Christ the Redeemer |

The checked-in manifest is `backend/seeds/data/worldwide_starter.json`. It records city/attraction Wikidata IDs, source URLs, source revisions, coordinates, licence, and check date. Names and coordinates were checked against Wikidata's structured entity records on 11 October 2026. Short descriptions are written for TRAV. Structured Wikidata records are CC0: https://www.wikidata.org/wiki/Wikidata:Licensing

Coordinates identify the attraction, not necessarily a ticket desk, car entrance, or hiking trailhead. Table Mountain's description explicitly explains that its pin marks the mountain. Visitor access points, transport modes, opening hours, fees, and photo rights require separate review. Photos and unknown fees/ratings are deliberately unset. This release does not claim field verification or full tourism information.

Country time zones are representative defaults for the included cities, not exhaustive lists. The traveler country detail labels them “Example time zone.” Multi-zone support belongs on city/destination records when itinerary scheduling is implemented. Geographic grouping uses states/regions supported by the current schema, including Tokyo metropolitan prefecture and Île-de-France.

## Import behavior

Render's existing startup script runs `python -m seeds.bootstrap_catalogue` after migrations. It only creates missing records, resolves actual database IDs, and imports in one transaction. A PostgreSQL advisory transaction lock serializes parallel import attempts. Existing edits are not overwritten; inactive/deleted records are not reactivated. Stable IDs protect starter city/destination/place records against duplicates after renamed records. Countries are matched by ISO2 and states by country/code, so changing those identity fields requires deliberate reconciliation.

The importer does not call any paid or external service. It reads a small local manifest. No new credentials, plans, or subscriptions are needed. It can be rerun with no additions for unchanged coverage.

## Existing large dataset

The repository also contains 250 country/territory records, 5,308 region records, and 152,970 city records. These have not been imported by this change. Their source/version, licence, uniqueness, and suitability must be reconciled before bulk import. Old destination seed records contain fixed IDs from another database and are not used.

## Verification and next milestone

Tests cover six-continent coverage, coordinate validation, repeat imports, preservation of renamed cities/destinations and admin descriptions, deleted-place preservation, inactive-parent handling, and public discovery routing.

Next: reviewed destination/attraction photographs with credits, additional famous places per city, direct global destination search, and then Save/Add to trip. Broader country coverage will be added through reviewed manifest batches rather than placeholder attraction records.
