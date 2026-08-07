import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import 'desktop_top_nav.dart';
import 'mobile_bottom_nav.dart';
import 'tablet_navigation_rail.dart';

class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.floatingActionButton,
    this.appBar,
  });

  bool _isDesktop(BuildContext context) {
    if (kIsWeb) return true;
    return Responsive.isDesktop(context);
  }

  bool _isTablet(BuildContext context) {
    if (kIsWeb) return false;
    return Responsive.isTablet(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isDesktop(context)) {
      return Scaffold(
        appBar: appBar ?? const DesktopTopNav(),
        body: body,
        floatingActionButton: floatingActionButton,
      );
    }

    if (_isTablet(context)) {
      return Scaffold(
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        body: Row(
  children: [
    TabletNavigationRail(
      selectedIndex: 0,
      onDestinationSelected: (index) {},
    ),
    const VerticalDivider(width: 1),
    Expanded(child: body),
  ],
),
      );
    }

    return Scaffold(
      extendBody: true,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: const MobileBottomNav(),
      body: body,
    );
  }
}