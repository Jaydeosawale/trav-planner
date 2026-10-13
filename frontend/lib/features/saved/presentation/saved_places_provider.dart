import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../destinations/data/place.dart';
import '../data/saved_places_api.dart';

final savedPlacesApiProvider = Provider<SavedPlacesApi>(
  (ref) => SavedPlacesApi(),
);
final savingPlacesProvider = StateProvider<Set<String>>((ref) {
  ref.watch(authProvider.select((auth) => auth.user?.id));
  return {};
});
final savedPlacesProvider =
    AsyncNotifierProvider<SavedPlacesController, List<TravelPlace>>(
      SavedPlacesController.new,
    );

class SavedPlacesController extends AsyncNotifier<List<TravelPlace>> {
  @override
  Future<List<TravelPlace>> build() async {
    final account = ref.watch(authProvider.select((auth) => auth.user?.id));
    if (account == null) return [];
    return ref.watch(savedPlacesApiProvider).load();
  }

  Future<void> toggle(TravelPlace place) async {
    final account = ref.read(authProvider).user?.id;
    if (account == null ||
        state.isLoading ||
        !state.hasValue ||
        ref.read(savingPlacesProvider).contains(place.id)) {
      return;
    }
    final saved = state.requireValue.any((item) => item.id == place.id);
    ref.read(savingPlacesProvider.notifier).state = {
      ...ref.read(savingPlacesProvider),
      place.id,
    };
    try {
      final api = ref.read(savedPlacesApiProvider);
      if (saved) {
        await api.remove(place.id);
      } else {
        if (place.discovered) await api.resolve(place.id);
        await api.save(place.id);
      }
      if (ref.read(authProvider).user?.id != account) return;
      final current = state.asData?.value;
      if (current != null) {
        state = AsyncData(
          saved
              ? current.where((item) => item.id != place.id).toList()
              : [place, ...current.where((item) => item.id != place.id)],
        );
      } else {
        ref.invalidateSelf();
      }
    } finally {
      if (ref.read(authProvider).user?.id == account) {
        ref.read(savingPlacesProvider.notifier).state = {
          ...ref.read(savingPlacesProvider),
        }..remove(place.id);
      }
    }
  }
}
