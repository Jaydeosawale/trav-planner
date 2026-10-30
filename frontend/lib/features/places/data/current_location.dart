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
  const LocationAccessFailure(
    this.message, {
    this.openSettings = false,
    this.deviceLocationSettings = false,
  });
  final String message;
  final bool openSettings;
  final bool deviceLocationSettings;
}

class CurrentLocationService {
  Future<LatLng> request() async {
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
    Position fix;
    try {
      // On Android the fused provider can show its native GPS-enable dialog.
      // Do not short-circuit it with an early service-enabled check.
      fix = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on LocationServiceDisabledException {
      throw const LocationAccessFailure(
        'Location is turned off. Enable it to continue, or enter a town.',
        deviceLocationSettings: true,
      );
    }
    // Approximate position only; no background tracking or persistent storage.
    return LatLng(
      double.parse(fix.latitude.toStringAsFixed(3)),
      double.parse(fix.longitude.toStringAsFixed(3)),
    );
  }

  Future<bool> openSettings() => Geolocator.openAppSettings();
  Future<bool> openDeviceSettings() => Geolocator.openLocationSettings();
}
