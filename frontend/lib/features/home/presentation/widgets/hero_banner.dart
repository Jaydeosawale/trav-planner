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

class HeroBanner extends ConsumerStatefulWidget {
  const HeroBanner({super.key});

  @override
  ConsumerState<HeroBanner> createState() =>
      _HeroBannerState();
}

class _HeroBannerState
    extends ConsumerState<HeroBanner> {
  final PageController _pageController =
      PageController();

  Timer? _autoPlayTimer;

  int _currentIndex = 0;

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay(
    List<BannerModel> banners,
  ) {
    if (banners.length <= 1) {
      return;
    }

    _autoPlayTimer?.cancel();

    _autoPlayTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!_pageController.hasClients) {
          return;
        }

        final nextIndex =
            (_currentIndex + 1) % banners.length;

        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(
            milliseconds: 600,
          ),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync =
        ref.watch(bannersProvider);

    return bannersAsync.when(
      loading: () =>
          _buildFallbackBanner(context),
      error: (_, __) =>
          _buildFallbackBanner(context),
      data: (banners) {
        if (banners.isEmpty) {
          return _buildFallbackBanner(context);
        }

        _startAutoPlay(banners);

        return SliverAppBar(
          expandedHeight:
              ResponsiveValues.heroHeight(context),
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
                  itemBuilder: (
                    context,
                    index,
                  ) {
                    final banner =
                        banners[index];

                    return _buildBannerImage(
                      banner.imageUrl,
                    );
                  },
                ),

                _buildGradient(),

                _buildContent(
                  context,
                  banners[_currentIndex],
                ),

                if (banners.length > 1)
                  _buildIndicators(
                    banners.length,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBannerImage(
    String imageUrl,
  ) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return Container(
          color: const Color(0xFF123B72),
        );
      },
      loadingBuilder: (
        context,
        child,
        loadingProgress,
      ) {
        if (loadingProgress == null) {
          return child.animate(
            onPlay: (controller) =>
                controller.repeat(
              reverse: true,
            ),
          ).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.08, 1.08),
            duration: 14.seconds,
          );
        }

        return Container(
          color: const Color(0xFF123B72),
          alignment: Alignment.center,
          child:
              const CircularProgressIndicator(
            color: Colors.white,
          ),
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
          stops: const [
            .05,
            .45,
            1,
          ],
          colors: [
            Colors.black.withValues(
              alpha: .05,
            ),
            Colors.black.withValues(
              alpha: .18,
            ),
            Colors.black.withValues(
              alpha: .68,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    BannerModel banner,
  ) {
    final bottomPadding = Responsive.value(
      context: context,
      mobile: 28,
      tablet: 44,
      desktop: 72,
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          ResponsiveValues.screenPadding(
            context,
          ),
          20,
          ResponsiveValues.screenPadding(
            context,
          ),
          bottomPadding,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Spacer(),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: .16,
                ),
                borderRadius:
                    BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: .20,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.amber,
                    size: 17,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AI Powered',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.w600,
                      fontSize:
                          ResponsiveValues
                              .heroSubtitle(
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fade(duration: 600.ms)
                .slideY(begin: .3),

            const SizedBox(height: 18),

            Text(
              banner.title.isNotEmpty
                  ? banner.title
                  : 'Trav Planner',
              style: TextStyle(
                color: Colors.white,
                fontSize:
                    ResponsiveValues.heroTitle(
                  context,
                ),
                fontWeight: FontWeight.w900,
                letterSpacing: -.8,
                height: 1,
              ),
            )
                .animate()
                .fade(delay: 250.ms)
                .slideY(begin: .25),

            if (banner.subtitle != null &&
                banner.subtitle!.isNotEmpty) ...[
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
                    color: Colors.white70,
                    fontSize:
                        ResponsiveValues
                            .heroSubtitle(
                      context,
                    ),
                    fontWeight:
                        FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              )
                  .animate()
                  .fade(delay: 500.ms),
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
                alignment:
                    Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(
                    maxWidth:
                        ResponsiveValues
                            .searchBarMaxWidth(
                      context,
                    ),
                  ),
                  child:
                      const PremiumSearchBar(),
                ),
              )
                  .animate()
                  .fade(delay: 700.ms)
                  .slideY(begin: .2),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIndicators(
    int count,
  ) {
    return Positioned(
      bottom: 18,
      left: 0,
      right: 0,
      child: Center(
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: List.generate(
            count,
            (index) {
              final selected =
                  index == _currentIndex;

              return AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 250,
                ),
                margin:
                    const EdgeInsets.symmetric(
                  horizontal: 3,
                ),
                width:
                    selected ? 22 : 7,
                height: 7,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white.withValues(
                    alpha: selected
                        ? .95
                        : .55,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackBanner(
    BuildContext context,
  ) {
    return SliverAppBar(
      expandedHeight:
          ResponsiveValues.heroHeight(
        context,
      ),
      pinned: false,
      stretch: true,
      elevation: 0,
      backgroundColor:
          const Color(0xFF123B72),
      automaticallyImplyLeading: false,
      flexibleSpace:
          FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration:
                  const BoxDecoration(
                gradient:
                    LinearGradient(
                  begin:
                      Alignment.topLeft,
                  end:
                      Alignment.bottomRight,
                  colors: [
                    Color(0xFF123B72),
                    Color(0xFF1684F5),
                  ],
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
          ],
        ),
      ),
    );
  }
}