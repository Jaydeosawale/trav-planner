# TRAV ocean UI

The app uses a light, photography-led travel identity: ocean blue #2563EB for primary actions, off-white #F8FAFC for the canvas, white cards, teal #14B8A6 for small highlights, and sunset orange #FB923C for the brand dot. Inter is bundled locally with its OFL license. Dark navy text keeps the light surfaces readable.

Home combines a destination spotlight, AI planning card, trip notebook shortcut and asymmetric inspiration cards. Explore shares those inspiration cards and retains its country, region and city search. AI shows the submitted question above the answer, with a clear send action and starter prompts. Trips uses a photographic empty state and the existing saved-trip data. Account screens inherit the shared palette and typography. All navigation and platform icons use the new identity.

Use 16–24px rounded corners, generous spacing and a restrained blue-to-teal gradient on the planning card. Keep text on photographs white with a dark gradient. Primary actions should stay blue. Inspiration is editorial; do not invent ratings, prices, booking confirmations or saved trips.

Validation: seven widget tests cover Home at 320, 360, 768 and 1280 pixels, account and AI layouts, destination-search navigation, and the trips-to-AI shortcut. Flutter analysis has no errors or warnings; 13 existing informational lints remain. The standard production JavaScript web build succeeds; existing secure-storage dependencies do not support the optional WebAssembly build. Booking and itinerary features are outside this visual update.
