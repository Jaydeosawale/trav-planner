import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../admin/presentation/pages/admin_dashboard_page.dart';
import '../../core/network/api_client.dart';
import '../../features/ai/presentation/pages/ai_search_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/widgets/require_sign_in.dart';
import '../../features/destinations/data/place.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/places/data/place_catalogue.dart';
import '../../features/places/presentation/browse_places_page.dart';
import '../../features/places/presentation/place_details_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/trips/presentation/pages/my_trips_page.dart';
import '../../features/trips/presentation/pages/trip_details_page.dart';
import '../../shared/navigation/adaptive_scaffold.dart';

final placeLinkProvider = FutureProvider.autoDispose
    .family<TravelPlace, String>((ref, id) async {
      final r = await ApiClient.dio.get('/places/${Uri.encodeComponent(id)}');
      return TravelPlace.fromJson(Map<String, dynamic>.from(r.data['data']));
    });

PlaceQuery placeQueryFromUri(Uri uri) => PlaceQuery(
  search: uri.queryParameters['search'] ?? '',
  countryId: uri.queryParameters['country'],
  cityId: uri.queryParameters['city'],
  type: placeCategories.any((c) => c.$1 == uri.queryParameters['category'])
      ? uri.queryParameters['category']!
      : 'all',
  photosOnly: uri.queryParameters['photos'] == 'true',
);

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = createAppRouter();
  ref.onDispose(router.dispose);
  return router;
});

GoRouter createAppRouter({String? initialLocation}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SplashPage()),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AdaptiveScaffold(
        navigationShell: shell,
        body: const SizedBox.shrink(),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const HomePage(embedded: true),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/explore',
              builder: (_, state) => BrowsePlacesPage(
                key: state.pageKey,
                initialQuery: placeQueryFromUri(state.uri),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/planner', builder: (_, _) => const AISearchPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/trips',
              builder: (_, _) => const SessionGate(child: MyTripsPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (_, _) => const SessionGate(child: ProfilePage()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/places/:id',
      builder: (_, state) => state.extra is TravelPlace
          ? PlaceDetailsPage(place: state.extra! as TravelPlace)
          : _LinkedPlace(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/trips/:id',
      builder: (_, state) =>
          SessionGate(child: TripDetailsPage(id: state.pathParameters['id']!)),
    ),
    GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
    GoRoute(
      path: '/admin',
      builder: (_, _) =>
          const SessionGate(admin: true, child: AdminDashboardPage()),
    ),
  ],
  errorBuilder: (context, _) => Scaffold(
    appBar: AppBar(title: const Text('Page unavailable')),
    body: Center(
      child: FilledButton(
        onPressed: () => context.go('/home'),
        child: const Text('Explore Trav'),
      ),
    ),
  ),
);

/// Restore a session even when a browser opens directly on a place or trip.
class SessionRestorer extends ConsumerStatefulWidget {
  const SessionRestorer({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<SessionRestorer> createState() => _SessionRestorerState();
}

class _SessionRestorerState extends ConsumerState<SessionRestorer> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted && ref.read(authProvider).status == AuthStatus.checking) {
        ref.read(authProvider.notifier).checkSession();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class SessionGate extends ConsumerWidget {
  const SessionGate({super.key, required this.child, this.admin = false});
  final Widget child;
  final bool admin;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth.isAuthenticated && (!admin || auth.isAdmin)) {
      return child;
    }
    if (auth.status == AuthStatus.checking)
      return const Center(child: CircularProgressIndicator());
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                admin
                    ? 'Administrator access required'
                    : 'Sign in to keep your plans together',
              ),
              const SizedBox(height: 16),
              if (auth.status == AuthStatus.unavailable) ...[
                const Text(
                  'Your session is kept. The connection is temporarily unavailable.',
                ),
                FilledButton(
                  onPressed: () =>
                      ref.read(authProvider.notifier).checkSession(),
                  child: const Text('Retry connection'),
                ),
              ] else if (!auth.isAuthenticated)
                FilledButton(
                  onPressed: () => ensureSignedIn(context, ref),
                  child: const Text('Sign in'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkedPlace extends ConsumerWidget {
  const _LinkedPlace({required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(placeLinkProvider(id))
      .when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => Scaffold(
          appBar: AppBar(title: const Text('Place unavailable')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This place link couldn’t load. It may need a fresh search.',
                ),
                TextButton(
                  onPressed: () => ref.invalidate(placeLinkProvider(id)),
                  child: const Text('Try again'),
                ),
                TextButton(
                  onPressed: () => context.go('/explore'),
                  child: const Text('Search places'),
                ),
              ],
            ),
          ),
        ),
        data: (place) => PlaceDetailsPage(place: place),
      );
}
