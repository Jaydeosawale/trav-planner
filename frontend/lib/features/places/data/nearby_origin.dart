import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../auth/presentation/providers/auth_provider.dart';

/// Explicitly shared GPS location, held only for this signed-in session.
/// Never written to preferences or substituted for a chosen destination town.
final nearbyOriginProvider = StateProvider<LatLng?>((ref) {
  ref.watch(authProvider.select((state) => state.user?.id));
  return null;
});
