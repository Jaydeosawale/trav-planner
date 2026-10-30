import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trav_planner/features/places/data/current_location.dart';

class PermissionPlatform extends GeolocatorPlatform {
  final calls = <String>[];
  LocationPermission current = LocationPermission.denied;
  LocationPermission answer = LocationPermission.whileInUse;
  bool gpsRejected = false;
  @override
  Future<LocationPermission> checkPermission() async {
    calls.add('check');
    return current;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    calls.add('permission');
    return answer;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    calls.add('earlyGpsCheck');
    return false;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    calls.add('nativePositionAndGpsDialog');
    if (gpsRejected) throw const LocationServiceDisabledException();
    return Position(
      latitude: 18.520432,
      longitude: 73.856742,
      timestamp: DateTime(2026),
      accuracy: 30,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() {
  late GeolocatorPlatform original;
  late PermissionPlatform platform;
  setUp(() {
    original = GeolocatorPlatform.instance;
    platform = PermissionPlatform();
    GeolocatorPlatform.instance = platform;
  });
  tearDown(() => GeolocatorPlatform.instance = original);
  test(
    'First use requests native permission then allows native GPS resolution',
    () async {
      final point = await CurrentLocationService().request();
      expect(platform.calls, [
        'check',
        'permission',
        'nativePositionAndGpsDialog',
      ]);
      expect(point.latitude, 18.52);
      expect(point.longitude, 73.857);
    },
  );
  test(
    'Already granted permission gets the current fix without another permission request',
    () async {
      platform.current = LocationPermission.whileInUse;
      await CurrentLocationService().request();
      expect(platform.calls, ['check', 'nativePositionAndGpsDialog']);
    },
  );
  test('Declined permission never requests a position', () async {
    platform.answer = LocationPermission.denied;
    await expectLater(
      CurrentLocationService().request(),
      throwsA(isA<LocationAccessFailure>()),
    );
    expect(platform.calls, ['check', 'permission']);
  });
  test('Declining GPS enablement offers device location settings', () async {
    platform.current = LocationPermission.whileInUse;
    platform.gpsRejected = true;
    await expectLater(
      CurrentLocationService().request(),
      throwsA(
        isA<LocationAccessFailure>().having(
          (e) => e.deviceLocationSettings,
          'device settings action',
          true,
        ),
      ),
    );
  });
}
