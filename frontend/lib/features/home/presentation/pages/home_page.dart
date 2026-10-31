import '../../../ai/presentation/pages/ai_search_page.dart';
import 'featured_destination_page.dart';
import '../../../../app/router/navigation_actions.dart';
import '../../../places/data/place_area.dart';
import '../../../places/data/place_catalogue.dart';
import '../widgets/home_places_section.dart';
import '../widgets/home_travel_hub.dart';
import '../../../booking/presentation/pages/booking_links_page.dart';
import '../../../explore/presentation/pages/nearby_places_page.dart';
import '../widgets/destination_spotlight.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/navigation/adaptive_scaffold.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../saved/presentation/pages/saved_page.dart';
import '../providers/home_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, this.embedded = false});
  final bool embedded;

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
                            const Spacer(),
                            const SizedBox(width: 8),
                            Semantics(
                              label: user == null ? 'Sign in' : 'Open profile',
                              button: true,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(28),
                                onTap: () =>
                                    Navigator.of(
                                      context,
                                      rootNavigator: user == null,
                                    ).push(
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
                        onOpen: (label, slug, redirectUrl) =>
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FeaturedDestinationPage(
                                  label: label,
                                  slug: slug,
                                  redirectUrl: redirectUrl,
                                ),
                              ),
                            ),
                        search: _HomeSearch(),
                      ),
                      const SizedBox(height: 10),
                      _HomeShortcuts(),
                      const SizedBox(height: 16),
                      const _PlanningInvitation(),
                      const SizedBox(height: 8),
                      const HomeTravelHub(personalOnly: true),
                      const HomePlacesSection(curated: true),
                      const HomeTravelHub(),
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

class _HomeSearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextField(
    readOnly: true,
    style: const TextStyle(fontSize: 14),
    onTap: () =>
        openPlaceSearch(context, const PlaceQuery(), focusSearch: true),
    decoration: const InputDecoration(
      hintText: 'Search towns & places',
      hintStyle: TextStyle(fontSize: 14),
      filled: true,
      fillColor: AppColors.surface,
      prefixIcon: Icon(Icons.search_rounded),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
    final compact = MediaQuery.sizeOf(context).width < 360 && !large;
    final children = actions
        .map(
          (action) => OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => action.$3)),
            child: Flex(
              direction: compact ? Axis.vertical : Axis.horizontal,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.$2, size: 17),
                SizedBox(width: compact ? 0 : 6, height: compact ? 5 : 0),
                if (compact)
                  Text(
                    action.$1,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 14),
                  )
                else
                  Flexible(
                    child: Text(
                      action.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
              ],
            ),
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

class _PlanningInvitation extends StatelessWidget {
  const _PlanningInvitation();
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Plan a trip with AI',
    child: Material(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.ocean, Color(0xFF185C68)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AISearchPage())),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFFFBF85),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A little idea. A great trip.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tell AI where you’d love to go.',
                        style: TextStyle(
                          color: Color(0xFFD1E8EA),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.north_east_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
