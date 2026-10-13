import 'package:flutter/material.dart';
import '../../../../core/widgets/travel_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../destinations/presentation/destination_details_page.dart';
import 'trip_editor_page.dart';
import '../../../itinerary/presentation/pages/itinerary_page.dart';

final tripDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, id) async {
    ref.watch(authProvider.select((auth) => auth.user?.id));
    return ref.watch(tripsApiProvider).get(id);
  },
);

class TripDetailsPage extends ConsumerWidget {
  const TripDetailsPage({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Your trip')),
    body: ref
        .watch(tripDetailsProvider(id))
        .when(
          skipLoadingOnReload: false,
          skipLoadingOnRefresh: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('This trip couldn’t be loaded.'),
                TextButton(
                  onPressed: () => ref.invalidate(tripDetailsProvider(id)),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
          data: (trip) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        trip['title']?.toString() ?? 'Your trip',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${trip['start_date']} — ${trip['end_date']}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${trip['travelers']} travelers · ${trip['status']}',
                              ),
                              const SizedBox(height: 12),
                              Text(
                                trip['budget_amount'] == null
                                    ? 'No budget set'
                                    : 'Planned budget: ${trip['budget_currency']} ${trip['budget_amount']}',
                              ),
                              if (trip['notes']?.toString().isNotEmpty ==
                                  true) ...[
                                const SizedBox(height: 12),
                                TravelMarkdown(
                                  content: trip['notes'].toString(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ItineraryPage(tripId: id),
                              ),
                            ),
                            icon: const Icon(Icons.view_timeline_outlined),
                            label: const Text('Day-by-day plan'),
                          ),
                          FilledButton.icon(
                            onPressed: () async {
                              final updated = await Navigator.of(context)
                                  .push<Map<String, dynamic>>(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TripEditorPage(trip: trip),
                                    ),
                                  );
                              if (updated != null) {
                                ref.invalidate(tripDetailsProvider(id));
                              }
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit trip'),
                          ),
                          if (trip['city_id'] != null)
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DestinationDetailsPage(
                                    cityId: trip['city_id'].toString(),
                                    name: 'Destination',
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Explore places'),
                            ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Remove this trip?'),
                                  content: const Text(
                                    'This removes it from My Trips.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Keep trip'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Remove'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true) return;
                              try {
                                await ref.read(tripsApiProvider).remove(id);
                                if (context.mounted) {
                                  Navigator.pop(context, true);
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Couldn’t remove the trip. Please try again.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove trip'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
  );
}
