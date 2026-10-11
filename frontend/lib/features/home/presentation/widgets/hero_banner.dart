import 'package:trav_planner/core/theme/app_colors.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/responsive_values.dart';
import '../../../../shared/widgets/premium_search_bar.dart';
import '../../data/models/banner_model.dart';
import '../providers/home_provider.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HeroBanner extends ConsumerStatefulWidget {
  const HeroBanner({super.key});

  @override
  ConsumerState<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends ConsumerState<HeroBanner> {
  final PageController _pageController = PageController();

  Timer? _autoPlayTimer;

  int _currentIndex = 0;

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay(List<BannerModel> banners) {
    if (banners.length <= 1) {
      return;
    }

    _autoPlayTimer?.cancel();

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients) {
        return;
      }

      final nextIndex = (_currentIndex + 1) % banners.length;

      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider);

    return bannersAsync.when(
      loading: () => _buildFallbackBanner(context),
      error: (_, __) => _buildFallbackBanner(context),
      data: (banners) {
        if (banners.isEmpty) {
          return _buildFallbackBanner(context);
        }

        _startAutoPlay(banners);

        return SliverAppBar(
          expandedHeight: ResponsiveValues.heroHeight(context),
          pinned: false,
          stretch: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.blurBackground,
            ],
            background: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: banners.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final banner = banners[index];

                    return _buildBannerImage(banner.imageUrl);
                  },
                ),

                _buildGradient(),

                _buildContent(context, banners[_currentIndex]),
                if (!kIsWeb) _buildProfileAvatar(context),
                if (banners.length > 1) _buildIndicators(banners.length),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBannerImage(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(color: AppColors.textPrimary);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.08, 1.08),
                duration: 14.seconds,
              );
        }

        return Container(
          color: AppColors.textPrimary,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: AppColors.surface),
        );
      },
    );
  }

  Widget _buildGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [.05, .45, 1],
          colors: [
            Colors.black.withValues(alpha: .05),
            Colors.black.withValues(alpha: .18),
            Colors.black.withValues(alpha: .68),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, BannerModel banner) {
    final bottomPadding = Responsive.value(
      context: context,
      mobile: 28,
      tablet: 44,
      desktop: 72,
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          ResponsiveValues.screenPadding(context),
          20,
          ResponsiveValues.screenPadding(context),
          bottomPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // AI BADGE
            //
            // Mobile / Tablet:
            // Positioned at the top-left so that the profile
            // avatar on the top-right sits on the same row.
            //
            // Web/Desktop:
            // The profile avatar is hidden from the hero.
            // ==================================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: .20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amber, size: 17),
                  const SizedBox(width: 6),
                  Text(
                    'AI Powered',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveValues.heroSubtitle(context),
                    ),
                  ),
                ],
              ),
            ).animate().fade(duration: 600.ms).slideY(begin: -.15),

            const Spacer(),

            Text(
              banner.title.isNotEmpty ? banner.title : 'Trav Planner',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: ResponsiveValues.heroTitle(context),
                fontWeight: FontWeight.w900,
                letterSpacing: -.8,
                height: 1,
              ),
            ).animate().fade(delay: 250.ms).slideY(begin: .25),

            if (banner.subtitle != null && banner.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: Responsive.value(
                  context: context,
                  mobile: 320,
                  tablet: 420,
                  desktop: 520,
                ),
                child: Text(
                  banner.subtitle!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: ResponsiveValues.heroSubtitle(context),
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ).animate().fade(delay: 500.ms),
            ],

            // ==================================================
            // HERO SEARCH
            //
            // Web/Desktop:
            // Search is in the top navigation.
            //
            // Mobile/Tablet:
            // Keep search inside the hero.
            // ==================================================
            if (!kIsWeb) ...[
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveValues.searchBarMaxWidth(context),
                  ),
                  child: const PremiumSearchBar(),
                ),
              ).animate().fade(delay: 700.ms).slideY(begin: .2),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.fullName ?? 'Trav Planner';

    return Positioned(
      top: 18,
      right: 20,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.surface, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _initials(userName),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'TP';
    }

    if (parts.length == 1) {
      final value = parts.first;
      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildIndicators(int count) {
    return Positioned(
      bottom: 18,
      left: 0,
      right: 0,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(count, (index) {
            final selected = index == _currentIndex;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: selected ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: selected ? .95 : .55),
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFallbackBanner(BuildContext context) {
    return SliverAppBar(
      expandedHeight: ResponsiveValues.heroHeight(context),
      pinned: false,
      stretch: true,
      elevation: 0,
      backgroundColor: AppColors.textPrimary,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.textPrimary, AppColors.primary],
                ),
              ),
            ),
            _buildContent(
              context,
              const BannerModel(
                id: 'fallback',
                title: 'Trav Planner',
                subtitle:
                    'Plan smarter journeys with AI-powered travel experiences tailored just for you.',
                imageUrl: '',
                displayOrder: 0,
                isActive: true,
              ),
            ),
            if (!kIsWeb) _buildProfileAvatar(context),
          ],
        ),
      ),
    );
  }
}
