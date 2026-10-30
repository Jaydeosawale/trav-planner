import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../auth/presentation/providers/auth_provider.dart';

/// Approximate GPS area. Location memory restores it for the same account.
/// Sharing it with AI still requires fresh consent each app session.
final nearbyOriginProvider = StateProvider<LatLng?>((ref) {
  ref.watch(authProvider.select((state) => state.user?.id));
  return null;
});
