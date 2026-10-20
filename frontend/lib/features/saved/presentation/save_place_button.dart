import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/widgets/require_sign_in.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../destinations/data/place.dart';
import 'saved_places_provider.dart';

class SavePlaceButton extends ConsumerWidget {
  const SavePlaceButton({super.key, required this.place, this.compact = false});
  final TravelPlace place;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authenticated = ref.watch(authProvider).user != null;
    final places = ref.watch(savedPlacesProvider);
    final busy = ref.watch(savingPlacesProvider).contains(place.id);
    final saved =
        places.asData?.value.any((item) => item.id == place.id) ?? false;
    final label = !authenticated
        ? 'Sign in to save'
        : places.hasError
        ? 'Retry saved places'
        : saved
        ? 'Remove from Saved'
        : 'Save place';
    final icon = busy || (authenticated && places.isLoading)
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded);
    Future<void> action() async {
      final resumed = !authenticated;
      if (resumed && !await ensureSignedIn(context, ref)) return;
      if (!context.mounted) return;
      if (!resumed && places.hasError) {
        ref.invalidate(savedPlacesProvider);
        return;
      }
      try {
        if (resumed) {
          final current = await ref.read(savedPlacesProvider.future);
          if (!context.mounted) return;
          if (current.any((p) => p.id == place.id)) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Already in Saved.')));
            return;
          }
        }
        await ref.read(savedPlacesProvider.notifier).toggle(place);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(saved ? 'Removed from Saved.' : 'Place saved.'),
            ),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Couldn’t update Saved. Please try again.'),
            ),
          );
        }
      }
    }

    final enabled = !busy && (!authenticated || !places.isLoading);
    if (compact) {
      return IconButton(
        tooltip: label,
        onPressed: enabled ? action : null,
        icon: icon,
      );
    }
    return OutlinedButton.icon(
      onPressed: enabled ? action : null,
      icon: icon,
      label: Text(label),
    );
  }
}
