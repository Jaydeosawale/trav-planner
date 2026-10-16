import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import '../../features/ai/presentation/pages/ai_search_page.dart';
import '../../features/places/presentation/browse_places_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/trips/presentation/pages/my_trips_page.dart';
import 'desktop_top_nav.dart';
import 'mobile_bottom_nav.dart';
import 'tablet_navigation_rail.dart';

class AdaptiveScaffold extends StatefulWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.floatingActionButton,
    this.appBar,
  });

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  int _selectedIndex = 0;
  final Set<int> _visited = {0};

  bool _isDesktop(BuildContext context) => Responsive.isDesktop(context);
  bool _isTablet(BuildContext context) => Responsive.isTablet(context);

  void _onNavigationSelected(int index) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedIndex = index;
      _visited.add(index);
    });
  }

  Widget _buildBody() => IndexedStack(
    index: _selectedIndex,
    children: List.generate(5, (index) {
      if (!_visited.contains(index)) return const SizedBox.shrink();
      return TickerMode(
        enabled: index == _selectedIndex,
        child: switch (index) {
          1 => const BrowsePlacesPage(),
          2 => const AISearchPage(),
          3 => const MyTripsPage(),
          4 => const ProfilePage(),
          _ => widget.body,
        },
      );
    }),
  );

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();

    // ==========================================================
    // Desktop / Web
    // ==========================================================

    if (_isDesktop(context)) {
      return Scaffold(
        appBar: DesktopTopNav(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onNavigationSelected,
        ),
        body: body,
        floatingActionButton: widget.floatingActionButton,
      );
    }

    // ==========================================================
    // Tablet
    // ==========================================================

    if (_isTablet(context)) {
      return Scaffold(
        appBar: widget.appBar,
        floatingActionButton: widget.floatingActionButton,
        body: Row(
          children: [
            TabletNavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onNavigationSelected,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    // ==========================================================
    // Mobile
    // ==========================================================

    return Scaffold(
      extendBody: false,
      appBar: widget.appBar,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: MobileBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavigationSelected,
      ),
      body: body,
    );
  }
}
