import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trav_planner/core/theme/app_theme.dart';
import 'package:trav_planner/features/home/presentation/pages/home_page.dart';
import 'package:trav_planner/features/home/presentation/providers/home_provider.dart';
import 'package:trav_planner/features/auth/presentation/pages/login_page.dart';
import 'package:trav_planner/features/ai/presentation/pages/ai_search_page.dart';
import 'package:trav_planner/shared/navigation/mobile_bottom_nav.dart';
import 'package:trav_planner/shared/navigation/desktop_top_nav.dart';

void main() {
  final boundary = GlobalKey();
  Future<void> setup(WidgetTester tester, Size size, Widget page) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      for (final family in ['Manrope', 'DM Sans']) {
        final loader = FontLoader(family);
        for (final weight in [400, 500, 600, 700, 800]) {
          loader.addFont(rootBundle.load('assets/fonts/${family == 'DM Sans' ? 'DMSans' : family}-$weight.ttf'));
        }
        await loader.load();
      }
    });
    await tester.pumpWidget(ProviderScope(overrides: [
      bannersProvider.overrideWith((ref) async => []),
      destinationsProvider.overrideWith((ref) async => []),
    ], child: MaterialApp(theme: AppTheme.dark, home: RepaintBoundary(key: boundary, child: page))));
    await tester.runAsync(() async { await Future<void>.delayed(const Duration(milliseconds: 300)); });
    await tester.pumpAndSettle();
  }
  Future<void> capture(String name) async {
    const output = String.fromEnvironment('TRAV_SCREENSHOT_DIR');
    if (output.isEmpty) return;
    final render = boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('$output/$name.png').writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  }
  for (final width in [360.0, 768.0, 1280.0]) {
    testWidgets('Home fits $width and uses viewport navigation', (tester) async {
      await setup(tester, Size(width, width == 1280 ? 1000 : 1200), const HomePage());
      expect(find.text('Somewhere\nworth going.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (width == 360) expect(find.byType(MobileBottomNav), findsOneWidget);
      if (width == 768) expect(find.byType(NavigationRail), findsOneWidget);
      if (width == 1280) expect(find.byType(DesktopTopNav), findsOneWidget);
      await tester.runAsync(() => capture('trav-home-${width.toInt()}')); 
      if (width == 360) {
        await tester.tap(find.text('Profile').last);
        await tester.pumpAndSettle();
        expect(find.text('Profile'), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.runAsync(() => capture('trav-profile')); 
      }
    });
  }
  testWidgets('Sign-in and AI layouts fit a narrow phone', (tester) async {
    await setup(tester, const Size(360, 1000), const LoginPage());
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => capture('trav-login')); 
    await setup(tester, const Size(360, 1000), const AISearchPage());
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => capture('trav-ai-planner')); 
  });
}
