import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../auth/presentation/providers/auth_provider.dart';

final currentLocationServiceProvider = Provider<CurrentLocationService>(
  (ref) => CurrentLocationService(),
);
final aiLocationEnabledProvider = StateProvider<bool>((ref) {
  ref.watch(authProvider.select((s) => s.user?.id));
  return false;
});

class LocationAccessFailure implements Exception {
  const LocationAccessFailure(this.message, {this.openSettings = false});
  final String message;
  final bool openSettings;
}

class CurrentLocationService {
  Future<LatLng> request() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationAccessFailure(
        'Turn on device location, or enter a town instead.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationAccessFailure(
        'Location is blocked. Allow it in app settings, or enter a town.',
        openSettings: true,
      );
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw const LocationAccessFailure(
        'Location wasn’t shared. You can enter a town instead.',
      );
    }
    final fix = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 20),
      ),
    );
    // Approximate position only; no background tracking or persistent storage.
    return LatLng(
      double.parse(fix.latitude.toStringAsFixed(3)),
      double.parse(fix.longitude.toStringAsFixed(3)),
    );
  }

  Future<bool> openSettings() => Geolocator.openAppSettings();
}
