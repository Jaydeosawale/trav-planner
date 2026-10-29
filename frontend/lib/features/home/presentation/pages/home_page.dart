import '../../../../app/router/navigation_actions.dart';
import '../../../places/presentation/area_selector.dart';
import '../../../places/data/place_area.dart';
import '../../../places/data/place_catalogue.dart';
import '../widgets/home_places_section.dart';
import '../../../booking/presentation/pages/booking_links_page.dart';
import '../../../explore/presentation/pages/nearby_places_page.dart';
import '../widgets/destination_spotlight.dart';
import '../../../destinations/presentation/destination_details_page.dart';
import '../../../destinations/data/place.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/navigation/adaptive_scaffold.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../../shared/widgets/travel_inspiration_grid.dart';
import '../../../trips/presentation/pages/my_trips_page.dart';
import '../../../ai/presentation/pages/ai_search_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../explore/presentation/pages/explore_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../saved/presentation/pages/saved_page.dart';
import '../providers/home_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, this.embedded = false});
  final bool embedded;

  void _explore(BuildContext context, [String query = '']) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => ExplorePage(initialQuery: query)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final content = SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(bannersProvider);
              ref.invalidate(destinationsProvider);
              ref.invalidate(placeCatalogueProvider);
              try {
                await ref.read(bannersProvider.future);
              } catch (_) {
                /* Provider displays the retry state. */
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 40 : 20,
                vertical: 12,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (constraints.maxWidth < 1024) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const BrandLogo(size: 30),
                            const SizedBox(width: 8),
                            const Expanded(child: AreaSelector(compact: true)),
                            const SizedBox(width: 8),
                            Semantics(
                              label: user == null ? 'Sign in' : 'Open profile',
                              button: true,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(28),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => user == null
                                        ? const LoginPage()
                                        : const ProfilePage(),
                                  ),
                                ),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surface,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  alignment: Alignment.center,
                                  child: user == null
                                      ? const Icon(Icons.person_outline)
                                      : Text(
                                          _initials(user.fullName),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      DestinationSpotlight(
                        banners: ref.watch(bannersProvider).asData?.value ?? [],
                        onSearch: (_) {},
                        search: _HomeSearch(),
                      ),
                      const SizedBox(height: 10),
                      _HomeShortcuts(),
                      const SizedBox(height: 8),
                      const HomePlacesSection(),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Somewhere new?',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _explore(context),
                            child: const Text('Destinations'),
                          ),
                        ],
                      ),
                      const Text('Choose a destination for more local places.'),
                      const SizedBox(height: 16),
                      _DestinationCollection(
                        onExplore: (query) => _explore(context, query),
                      ),
                      const SizedBox(height: 28),
                      if (wide)
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: _PlannerPanel()),
                            SizedBox(width: 24),
                            Expanded(flex: 4, child: _TripShortcut()),
                          ],
                        )
                      else ...[
                        const _PlannerPanel(),
                        const SizedBox(height: 16),
                        const _TripShortcut(),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    return embedded ? content : AdaptiveScaffold(body: content);
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    return parts.isEmpty
        ? 'T'
        : parts.take(2).map((p) => p[0]).join().toUpperCase();
  }
}

class _PlannerPanel extends StatelessWidget {
  const _PlannerPanel();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.ocean,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.sunset, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'YOUR PERSONAL TRAVEL PLANNER',
                style: TextStyle(
                  color: Color(0xFFCFDFD7),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'The idea is yours.\nThe plan is on us.',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text(
          'Dates, budget, interests. Start with what matters to you.',
          style: TextStyle(color: Color(0xFFCFDFD7), fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sunset,
              foregroundColor: AppColors.ocean,
            ),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AISearchPage())),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Plan my trip'), Icon(Icons.north_east_rounded)],
            ),
          ),
        ),
      ],
    ),
  );
}

class _DestinationCollection extends ConsumerWidget {
  const _DestinationCollection({required this.onExplore});
  final ValueChanged<String> onExplore;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(destinationsProvider)
      .when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, stack) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text('Destinations are taking a little longer to load.'),
              ),
              TextButton(
                onPressed: () => ref.invalidate(destinationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (destinations) {
          final active = destinations
              .where((d) => d.isActive && d.image?.startsWith('http') == true)
              .toList();
          if (active.isEmpty) {
            return TravelInspirationGrid(onSelect: onExplore);
          }
          return SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: active.length,
              separatorBuilder: (_, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final destination = active[index];
                return SizedBox(
                  width: 230,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DestinationDetailsPage(
                          cityId: destination.cityId,
                          name: destination.title,
                          description:
                              destination.description ??
                              destination.shortDescription,
                          imageUrl: destination.image,
                          center: validCoordinates(
                            destination.latitude,
                            destination.longitude,
                          ),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            height: 150,
                            width: 230,
                            child:
                                destination.image != null &&
                                    destination.image!.isNotEmpty
                                ? Image.network(
                                    destination.image!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, error, stack) =>
                                        const _ImagePlaceholder(),
                                  )
                                : const _ImagePlaceholder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          destination.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          destination.shortDescription ?? destination.country,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.surfaceVariant,
    child: Center(child: Icon(Icons.landscape_outlined, size: 40)),
  );
}

class _TripShortcut extends StatelessWidget {
  const _TripShortcut();
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: AppColors.border),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const MyTripsPage())),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFFFF3E7),
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.luggage_outlined, color: AppColors.warning),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your travel notebook',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Keep your plans in one place',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    ),
  );
}

class _HomeSearch extends StatefulWidget {
  @override
  State<_HomeSearch> createState() => _HomeSearchState();
}

class _HomeSearchState extends State<_HomeSearch> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() =>
      openPlaceSearch(context, PlaceQuery(search: _controller.text.trim()));
  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    textInputAction: TextInputAction.search,
    onSubmitted: (_) => _search(),
    onTapOutside: (_) => FocusScope.of(context).unfocus(),
    decoration: InputDecoration(
      hintText: 'Town, landmark or café',
      filled: true,
      fillColor: AppColors.surface,
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: IconButton(
        tooltip: 'Search places',
        onPressed: _search,
        icon: const Icon(Icons.arrow_forward_rounded),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}

class _HomeShortcuts extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = <(String, IconData, Widget)>[
      ('Nearby', Icons.near_me_outlined, const NearbyPlacesPage()),
      (
        'Book',
        Icons.flight_takeoff,
        BookingLinksPage(destination: ref.watch(chosenPlaceAreaProvider)?.name),
      ),
      ('Saved', Icons.bookmark_border, const SavedPage()),
    ];
    final large = MediaQuery.textScalerOf(context).scale(14) > 21;
    final children = actions
        .map(
          (action) => OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => action.$3)),
            icon: Icon(action.$2, size: 17),
            label: Text(action.$1),
          ),
        )
        .toList();
    return large
        ? Wrap(spacing: 8, runSpacing: 8, children: children)
        : Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: children[i]),
              ],
            ],
          );
  }
}
