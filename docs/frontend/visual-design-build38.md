# Trav visual design pass — build 38

31 October 2026. Ocean Escape remains the selected direction.

## Reference observations and decisions

Official product pages were reviewed; these are design interpretations, not claims of hands-on authenticated competitor testing.

- [Airbnb Summer Release](https://news.airbnb.com/product-releases/airbnb-2025-summer-release): discovery is organized around experiences and destinations, with large photography. Retain Trav's large approved hero and complete destination photos; reduce repeated outlined-box emphasis.
- [Skyscanner Everywhere](https://www.skyscanner.net/flights/advice/skyscanner-everywhere-search-how-to-find-flights-to-anywhere-in-the-world): exploration can begin before deciding a destination. Keep activity ideas available to browse, with town/location requested only when needed. No fabricated fares or promotions.
- [Wanderlog](https://wanderlog.com/plan-a-trip): plans, maps and budgets form a connected workspace. Preserve the direct day-plan/map/budget actions delivered in build 37.

## Implementation

- Keep ocean blue as the action color. Use deep ocean with a restrained peach icon for the Home AI invitation; muted teal, lavender, sand and green continue to distinguish activity themes.
- Add a single tappable AI invitation on Home, leading to the existing authenticated planner. No new model request is made on Home.
- Use two activity columns at narrow phone sizes when text fits, three on desktop, and one with large text. Remove the previous 320px-phone stack of six full-width blocks.
- Soften background/border contrast; reduce section and utility heading sizes to 20px and 16px while retaining readable body text and the approved hero typography.
- Set consistent 20px app-bar titles across screens. Preserve native text scaling.
- Use a white bottom navigation surface and a distinct blue selected pill; keep Home, Explore, AI Planner and My Trips only.
- Add slight elevation to shared place cards, lighten title weight, and preserve full-photo display, same-photo blurred fill, photo credits and save/detail actions.

No data provider, payment behavior, AI allowance, login flow, logo, location-sharing behavior or store release setting changes. Build is for Trav Test; Google Play remains held.

## Validation

Automated app regression and screenshot exports cover the affected shared styles and Home navigation at phone/tablet/desktop sizes. The new Home AI invitation is checked to open the existing sign-in-gated planner and return safely to Home. Controlled screenshots do not establish live place inventory or photo coverage.

Final checks: all 116 Flutter tests passed. Analysis completed with no errors or warnings; 21 informational style/deprecation lints remain. Phone/tablet/desktop fixture renders were inspected, including 320px and 1280px Home and the shared Explore place card.
