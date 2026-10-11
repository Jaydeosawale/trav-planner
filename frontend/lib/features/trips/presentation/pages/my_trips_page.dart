import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ai/presentation/pages/ai_search_page.dart';

final myTripsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await ApiClient.dio.get('/trips/');
  final data = response.data['data'] as Map<String, dynamic>;
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
          ref
              .watch(myTripsProvider)
              .when(
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
                              const Icon(Icons.luggage_outlined, size: 40),
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
                                    contentPadding: const EdgeInsets.all(20),
                                    leading: const Icon(
                                      Icons.luggage_outlined,
                                      color: AppColors.accent,
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
        ],
      ),
    ),
  );
}
