import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ai/presentation/pages/ai_search_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'trip_editor_page.dart';
import 'trip_details_page.dart';

final tripPageProvider = StateProvider<int>((ref) {
  ref.watch(authProvider.select((auth) => auth.user?.id));
  return 1;
});
final tripPagesProvider = StateProvider<int>((ref) => 1);

final myTripsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authProvider.select((auth) => auth.user?.id));
  if (user == null) return [];
  final page = ref.watch(tripPageProvider);
  final data = await ref.watch(tripsApiProvider).list(page);
  ref.read(tripPagesProvider.notifier).state =
      (data['pages'] as num?)?.toInt() ?? 1;
  return (data['items'] as List)
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
});

class MyTripsPage extends ConsumerWidget {
  const MyTripsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('My Trips')),
    body: RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myTripsProvider);
        await ref.read(myTripsProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Your next chapter.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Your saved travel plans, together in one place.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              final created = await Navigator.of(context)
                  .push<Map<String, dynamic>>(
                    MaterialPageRoute(builder: (_) => const TripEditorPage()),
                  );
              if (created != null) {
                ref.read(tripPageProvider.notifier).state = 1;
                ref.invalidate(myTripsProvider);
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create a trip'),
          ),
          const SizedBox(height: 20),
          ref
              .watch(myTripsProvider)
              .when(
                skipLoadingOnReload: false,
                skipLoadingOnRefresh: false,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text('We couldn’t load your trips.'),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => ref.invalidate(myTripsProvider),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (trips) => trips.isEmpty
                    ? Card(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  'assets/images/destinations/switzerland_1.jpg',
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'A little adventure awaits.',
                                style: Theme.of(context).textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'When you save a trip, it will appear here.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AISearchPage(),
                                  ),
                                ),
                                child: const Text('Explore ideas with AI'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: trips
                            .map(
                              (trip) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Card(
                                  child: ListTile(
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TripDetailsPage(
                                            id: trip['id'].toString(),
                                          ),
                                        ),
                                      );
                                      ref.invalidate(myTripsProvider);
                                    },
                                    contentPadding: const EdgeInsets.all(20),
                                    leading: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.luggage_outlined,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    title: Text(
                                      trip['title']?.toString() ??
                                          'Untitled trip',
                                    ),
                                    subtitle: Text(
                                      '${trip['start_date'] ?? 'Dates to come'} — ${trip['end_date'] ?? ''}\n${trip['travelers'] ?? 1} travelers · ${trip['status'] ?? 'draft'}',
                                    ),
                                    isThreeLine: true,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: ref.watch(tripPageProvider) > 1
                    ? () => ref.read(tripPageProvider.notifier).state--
                    : null,
                child: const Text('Previous'),
              ),
              Text('Page ${ref.watch(tripPageProvider)}'),
              TextButton(
                onPressed:
                    ref.watch(tripPageProvider) < ref.watch(tripPagesProvider)
                    ? () => ref.read(tripPageProvider.notifier).state++
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
