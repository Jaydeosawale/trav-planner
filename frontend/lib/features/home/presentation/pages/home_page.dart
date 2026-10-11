import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/navigation/adaptive_scaffold.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../ai/presentation/pages/ai_search_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../explore/presentation/pages/explore_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../saved/presentation/pages/saved_page.dart';
import '../providers/home_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _explore(BuildContext context, [String query = '']) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => ExplorePage(initialQuery: query)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    return AdaptiveScaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(bannersProvider);
                ref.invalidate(destinationsProvider);
                try { await ref.read(bannersProvider.future); } catch (_) { /* Provider displays the retry state. */ }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 40 : 24,
                  vertical: 24,
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
                              const BrandLogo(size: 42),
                              Semantics(
                                label: user == null
                                    ? 'Sign in'
                                    : 'Open profile',
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
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
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
                          const SizedBox(height: 32),
                        ],
                        const _Eyebrow('LESS PLANNING. MORE LIVING.'),
                        const SizedBox(height: 20),
                        Text(
                          'Somewhere\nworth going.',
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(fontSize: wide ? 58 : 40),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Find a place. Make it your adventure.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 28),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 650),
                          child: TextField(
                            textInputAction: TextInputAction.search,
                            onSubmitted: (value) =>
                                _explore(context, value.trim()),
                            decoration: InputDecoration(
                              hintText: 'Where do you want to go?',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: IconButton(
                                tooltip: 'Explore destinations and filters',
                                onPressed: () => _explore(context),
                                icon: const Icon(Icons.tune_rounded),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Expanded(
                                flex: 6,
                                child: _FeaturedDestination(),
                              ),
                              const SizedBox(width: 24),
                              const Expanded(flex: 4, child: _PlannerPanel()),
                            ],
                          )
                        else ...[
                          const _FeaturedDestination(),
                          const SizedBox(height: 24),
                          const _PlannerPanel(),
                        ],
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 18,
                          runSpacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: () => _explore(context),
                              icon: const Icon(Icons.location_on_outlined),
                              label: const Text('Discover places'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SavedPage(),
                                ),
                              ),
                              icon: const Icon(Icons.bookmark_border_rounded),
                              label: const Text('Keep your favorites'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'More places to discover',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _DestinationCollection(
                          onExplore: (query) => _explore(context, query),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
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

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.8,
      color: AppColors.textSecondary,
    ),
  );
}

class _FeaturedDestination extends ConsumerWidget {
  const _FeaturedDestination();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(bannersProvider).asData?.value;
    final banner = banners != null && banners.isNotEmpty ? banners.first : null;
    return Semantics(
      label: banner?.title ?? 'Bali destination inspiration',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          height: 290,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (banner != null)
                Image.network(
                  banner.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) => Image.asset(
                    'assets/images/destinations/bali_1.jpg',
                    fit: BoxFit.cover,
                  ),
                )
              else
                Image.asset(
                  'assets/images/destinations/bali_1.jpg',
                  fit: BoxFit.cover,
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE6061B17)],
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton.filled(
                  tooltip: 'View saved destinations',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.background,
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const SavedPage())),
                  icon: const Icon(Icons.favorite_border_rounded),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'A LITTLE WONDER. A LITTLE WANDER.',
                      style: TextStyle(
                        color: Color(0xFFF6E2B4),
                        fontSize: 10,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      banner?.title ?? 'Bali, at your pace.',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      banner?.subtitle ?? 'Temples. Quiet mornings. Ocean air.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlannerPanel extends StatelessWidget {
  const _PlannerPanel();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(26),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('YOUR PERSONAL TRAVEL PLANNER'),
        const SizedBox(height: 22),
        Text(
          'The idea is yours.\nThe plan is on us.',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        const Text(
          'Dates, budget, interests. We bring it together.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AISearchPage())),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Plan with AI'), Icon(Icons.north_east_rounded)],
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
          final active = destinations.where((d) => d.isActive).toList();
          if (active.isEmpty) {
            return const Text(
              'New destinations will appear here soon.',
              style: TextStyle(color: AppColors.textSecondary),
            );
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
                    onTap: () => onExplore(destination.title),
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
