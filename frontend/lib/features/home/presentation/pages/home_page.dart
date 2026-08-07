import 'package:flutter/material.dart';

import '../widgets/ai_planner_card.dart';
import '../widgets/category_list.dart';
import '../widgets/continue_trip_card.dart';
import '../widgets/greeting_widget.dart';
import '../widgets/hero_banner.dart';
import '../widgets/popular_destinations.dart';
import '../widgets/trending_section.dart';
import '../widgets/weather_card.dart';
import '../../../../shared/navigation/adaptive_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          const SliverToBoxAdapter(
  child: SizedBox(height: 350),
),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              120,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                const [
                  GreetingWidget(),

                  SizedBox(height: 26),

                  CategoryList(),

                  SizedBox(height: 34),

                  PopularDestinations(),

                  SizedBox(height: 36),

                  AIPlannerCard(),

                  SizedBox(height: 26),

                  WeatherCard(),

                  SizedBox(height: 26),

                  ContinueTripCard(),

                  SizedBox(height: 36),

                  TrendingSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}