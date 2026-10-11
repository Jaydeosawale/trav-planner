# TRAV ribbon journey branding

The approved ribbon T combines an airplane, a flight path, a teal mountain and a small orange sunrise. `frontend/assets/images/branding/trav-symbol.png` is the transparent production asset, generated with the built-in image generation tool. The shared `BrandLogo` widget pairs it with the bundled Inter wordmark; all screens use the same identity.

Production asset prompt:

> Extract and faithfully reproduce ONLY the approved ribbon T symbol from the large upper-left logo in this reference. Deliver one centered standalone logo mark on a genuinely transparent background, square canvas, symbol fills 85 percent of canvas with safe even padding. Preserve EXACT silhouette and proportional relationships: gently wavy rounded ocean-blue top crossbar, dark navy folded underside at left, flowing blue ribbon central stem, clean white sweeping flight trail ending at a small white airplane upper right, simple broad teal mountain base and small orange sun tucked behind it. Sun is small, width around one third of mountain, same as reference. No wordmark, no app-icon rounded square, no labels, no presentation background, no gray halo, no border, no extra elements. Remove all white/off-white board background outside the mark while preserving intentional WHITE airplane and white ribbon cutout within the blue symbol. Do not invent a new logo or alter geometry; this is the clean production asset of the selected design. Crisp smooth edges, high resolution, consistent fills.

To export all launcher/browser icons, run `dart run tool/trav_brand_assets.dart` from `frontend`. Regenerate splash screens with `dart run flutter_native_splash:create`.

## Android release

Build with `flutter build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://jaydeo-trav-planner-api.onrender.com/api/v1`.

The private release key and its settings are stored locally in `frontend/android/trav-release.jks` and `frontend/android/key.properties`, excluded from Git. Back up both securely and retain the same signing key for future updates. Release builds without those files remain unsigned; debug builds retain normal debug signing. Never publish the key or settings.

Version 1.0.1 (build 2), app ID `com.jaydeo.travplanner`, display name Trav. Android release networking is enabled. Email/password login is available; unconfigured Google and Apple buttons are omitted.
