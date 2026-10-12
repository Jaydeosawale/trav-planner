import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../destinations/data/place.dart';
import '../../../destinations/presentation/destination_details_page.dart';
import '../../../explore/presentation/pages/explore_page.dart';
import '../saved_places_provider.dart';
import '../save_place_button.dart';

class SavedPage extends ConsumerStatefulWidget {
  const SavedPage({super.key});
  @override
  ConsumerState<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends ConsumerState<SavedPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(savedPlacesProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authenticated = ref.watch(authProvider).user != null;
    final saved = ref.watch(savedPlacesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Saved places')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(savedPlacesProvider);
          try {
            await ref.read(savedPlacesProvider.future);
          } catch (_) {
            /* Retry is displayed in the list. */
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Keep a little inspiration.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your favorite places, ready for your next adventure.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    if (!authenticated)
                      _Message(
                        text:
                            'Sign in to keep your saved places together across devices.',
                        action: 'Sign in',
                        onAction: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        ),
                      )
                    else
                      saved.when(
                        skipLoadingOnReload: false,
                        skipLoadingOnRefresh: false,
                        loading: () => const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, _) => _Message(
                          text: 'We couldn’t load your saved places.',
                          action: 'Try again',
                          onAction: () => ref.invalidate(savedPlacesProvider),
                        ),
                        data: (places) => places.isEmpty
                            ? _Message(
                                text:
                                    'A place catches your eye? Save it from its details and find it here.',
                                action: 'Discover places',
                                onAction: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ExplorePage(),
                                  ),
                                ),
                              )
                            : Column(
                                children: places
                                    .map(
                                      (place) => _SavedPlaceCard(place: place),
                                    )
                                    .toList(),
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.text,
    required this.action,
    required this.onAction,
  });
  final String text, action;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Icon(
            Icons.bookmark_border_rounded,
            size: 42,
            color: AppColors.ocean,
          ),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    ),
  );
}

class _SavedPlaceCard extends StatelessWidget {
  const _SavedPlaceCard({required this.place});
  final TravelPlace place;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: place.cityId == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DestinationDetailsPage(
                  cityId: place.cityId!,
                  name: place.name,
                  center: place.point,
                  initialPlace: place,
                ),
              ),
            ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 72,
                height: 80,
                child: place.imageUrl?.isNotEmpty == true
                    ? Image.network(
                        place.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _ImageFallback(),
                      )
                    : const _ImageFallback(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    place.type.replaceAll('_', ' '),
                    style: const TextStyle(color: AppColors.secondary),
                  ),
                  if (place.address?.isNotEmpty == true)
                    Text(
                      place.address!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            SavePlaceButton(place: place, compact: true),
          ],
        ),
      ),
    ),
  );
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.surfaceVariant,
    child: Icon(Icons.landscape_outlined, color: AppColors.secondary),
  );
}
