import '../../../../app/router/navigation_actions.dart';
import '../../../places/data/place_area.dart';
import '../../../places/data/place_catalogue.dart';
import '../widgets/home_places_section.dart';
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
    onTap: () =>
        openPlaceSearch(context, const PlaceQuery(), focusSearch: true),
    decoration: const InputDecoration(
      hintText: 'Search towns & places',
      filled: true,
      fillColor: AppColors.surface,
      prefixIcon: Icon(Icons.search_rounded),
      suffixIcon: Icon(Icons.arrow_forward_rounded),
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
