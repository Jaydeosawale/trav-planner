import '../../../places/presentation/area_selector.dart';
import '../../../places/data/nearby_origin.dart';
import '../../../explore/presentation/pages/nearby_places_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/router/navigation_actions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../booking/presentation/pages/booking_links_page.dart';
import '../../../places/data/place_area.dart';
import '../../../places/data/place_catalogue.dart';
import '../../../saved/presentation/saved_places_provider.dart';
import '../../../trips/presentation/pages/my_trips_page.dart';

/// Small, explainable suggestions from the user's actual trips and saves.
class HomeTravelHub extends ConsumerWidget {
  const HomeTravelHub({super.key, this.personalOnly = false});
  final bool personalOnly;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authProvider).isAuthenticated;
    final tripState = signedIn ? ref.watch(myTripsProvider) : null;
    final savedState = signedIn ? ref.watch(savedPlacesProvider) : null;
    final trips = tripState?.isLoading == false
        ? tripState?.asData?.value ?? <Map<String, dynamic>>[]
        : <Map<String, dynamic>>[];
    final saved = savedState?.isLoading == false
        ? savedState?.asData?.value ?? []
        : [];
    final area = ref.watch(chosenPlaceAreaProvider);
    final origin = ref.watch(nearbyOriginProvider);
    Future<void> chooseDayArea(String? type) async {
      final choice = await showModalBottomSheet<String>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Where is your day happening?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a town or share your location to find places around you.',
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(
                    Icons.location_city_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Enter a town'),
                  subtitle: const Text(
                    'Explore here or somewhere you’re going',
                  ),
                  onTap: () => Navigator.pop(sheetContext, 'town'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.secondary,
                  ),
                  title: const Text('Use my location'),
                  subtitle: const Text(
                    'Location permission is requested only when you choose this',
                  ),
                  onTap: () => Navigator.pop(sheetContext, 'gps'),
                ),
              ],
            ),
          ),
        ),
      );
      if (!context.mounted) return;
      if (choice == 'town') {
        await showPlaceAreaPicker(
          context,
          onChanged: (selected) {
            if (type != null && context.mounted) {
              // Close the picker before navigating to the selected category.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  openPlaceSearch(
                    context,
                    PlaceQuery(type: type, cityId: selected.cityId),
                  );
                }
              });
            }
          },
        );
      } else if (choice == 'gps') {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NearbyPlacesPage(
              initialKind: type ?? 'all',
              useCurrentLocation: true,
            ),
          ),
        );
      }
    }

    void openDay(String type) {
      if (area?.cityId != null) {
        openPlaceSearch(context, PlaceQuery(type: type, cityId: area!.cityId));
      } else if (origin != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                NearbyPlacesPage(initialKind: type, initialOrigin: origin),
          ),
        );
      } else {
        chooseDayArea(type);
      }
    }

    final counts = <String, int>{};
    for (final place in saved) {
      counts[place.type] = (counts[place.type] ?? 0) + 1;
    }
    final types =
        counts.keys
            .where((type) => placeCategories.any((c) => c.$1 == type))
            .toList()
          ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final favorite = types.isEmpty ? null : types.first;
    void browse(String type, {String? city}) => openPlaceSearch(
      context,
      PlaceQuery(type: type, cityId: city ?? area?.cityId),
      focusSearch: (city ?? area?.cityId) == null,
    );
    if (personalOnly) {
      return Column(
        children: [
          if (trips.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.luggage_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Pick up your plans'),
                subtitle: Text(
                  trips.first['title']?.toString() ?? 'Your saved trip',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openTrip(context, trips.first['id'].toString()),
              ),
            ),
          if (trips.isNotEmpty && trips.first['city_id'] != null)
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.travel_explore,
                  color: AppColors.secondary,
                ),
                title: const Text('More around your trip'),
                subtitle: Text(
                  'Inspired by ${trips.first['title'] ?? 'your saved trip'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    browse('all', city: trips.first['city_id'].toString()),
              ),
            ),
          if (favorite != null)
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.bookmarks_outlined,
                  color: AppColors.secondary,
                ),
                title: Text(
                  'More ${placeCategories.firstWhere((c) => c.$1 == favorite).$2.toLowerCase()} for you',
                ),
                subtitle: const Text('Based on your saved places'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => browse(
                  favorite,
                  city: saved.where((p) => p.type == favorite).first.cityId,
                ),
              ),
            ),
        ],
      );
    }
    final ideas = [
      (
        'Coffee & slow mornings',
        'Cafés & quiet corners',
        'cafe',
        Icons.local_cafe_outlined,
        const Color(0xFFF3E9DB),
      ),
      (
        'Views worth a pause',
        'Scenic viewpoints',
        'viewpoint',
        Icons.landscape_outlined,
        const Color(0xFFE1EBFF),
      ),
      (
        'A food-filled day',
        'Restaurants & local food',
        'restaurant',
        Icons.restaurant_outlined,
        const Color(0xFFFFE9DB),
      ),
      (
        'A little fresh air',
        'Parks & open spaces',
        'park',
        Icons.park_outlined,
        const Color(0xFFDDF4E8),
      ),
      (
        'Stories & culture',
        'Museums, art & history',
        'museum',
        Icons.museum_outlined,
        const Color(0xFFE8E3FA),
      ),
      (
        'Slow by the water',
        'Beaches & coastlines',
        'beach',
        Icons.beach_access_outlined,
        const Color(0xFFDCEFFA),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'What kind of day?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Icon(
                Icons.location_on_outlined,
                size: 17,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                area != null
                    ? 'Ideas around ${area.name}'
                    : origin != null
                    ? 'Near your shared location'
                    : 'Choose a town or use your location',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => chooseDayArea(null),
              child: Text(
                area != null || origin != null ? 'Change' : 'Set area',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
            final columns = largeText || constraints.maxWidth < 260
                ? 1
                : constraints.maxWidth >= 800
                ? 3
                : 2;
            Widget card((String, String, String, IconData, Color) idea) {
              final ink = switch (idea.$3) {
                'cafe' => const Color(0xFF79502E),
                'viewpoint' => const Color(0xFF2452A1),
                'restaurant' => const Color(0xFFAA461A),
                'park' => const Color(0xFF23704C),
                'museum' => const Color(0xFF6945A0),
                _ => const Color(0xFF146A87),
              };
              return Material(
                color: idea.$5,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => openDay(idea.$3),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ink.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(idea.$4, color: ink, size: 22),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          idea.$1,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ink,
                            fontSize: 14,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          idea.$2,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (var i = 0; i < ideas.length; i += columns)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (
                            var j = i;
                            j < i + columns && j < ideas.length;
                            j++
                          ) ...[
                            if (j > i) const SizedBox(width: 12),
                            Expanded(child: card(ideas[j])),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.flight_takeoff),
            title: const Text('Compare travel options'),
            subtitle: const Text('Flights, trains and stays on supplier sites'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BookingLinksPage(destination: area?.name),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
