import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/responsive/responsive_values.dart';
import '../../../../shared/widgets/premium_search_bar.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: ResponsiveValues.heroHeight(context),
      pinned: false,
      stretch: true,
      elevation: 0,
      backgroundColor: Colors.transparent,

      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              "assets/images/hero/hero_1.jpg",
              fit: BoxFit.cover,
            )
                .animate(
                  onPlay: (controller) =>
                      controller.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.08, 1.08),
                  duration: 14.seconds,
                ),

            Container(
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
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  20,
                  24,
                  28,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Spacer(),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        borderRadius:
                            BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: .20,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.amber,
                            size: 17,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "AI Powered",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize:
                                  ResponsiveValues.heroSubtitle(
                                      context),
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
                      "Trav Planner",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize:
                            ResponsiveValues.heroTitle(context),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.8,
                        height: 1,
                      ),
                    )
                        .animate()
                        .fade(delay: 250.ms)
                        .slideY(begin: .25),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: 320,
                      child: Text(
                        "Plan smarter journeys with AI-powered travel experiences tailored just for you.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize:
                              ResponsiveValues.heroSubtitle(
                                  context),
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                      ),
                    ).animate().fade(delay: 500.ms),

                    const SizedBox(height: 28),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth:
                              ResponsiveValues.searchBarMaxWidth(
                                  context),
                        ),
                        child: const PremiumSearchBar(),
                      ),
                    )
                        .animate()
                        .fade(delay: 700.ms)
                        .slideY(begin: .2),
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