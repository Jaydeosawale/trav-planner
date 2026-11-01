import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/core/theme/app_theme.dart';
import 'package:trav_planner/features/auth/presentation/providers/auth_provider.dart';
import 'package:trav_planner/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:trav_planner/features/profile/presentation/pages/profile_page.dart';
import 'package:trav_planner/features/ai/presentation/pages/ai_search_page.dart';
import 'package:trav_planner/features/ai/data/datasources/ai_api.dart';
import 'saved_places_test.dart' show TestAuth;
import 'place_browsing_product_test.dart' show fontsAndPhoto, captureScreen;

void main() {
  testWidgets(
    'Mobile profile opens password recovery with the signed-in email',
    (tester) async {
      tester.view.physicalSize = const Size(320, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await fontsAndPhoto(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith(TestAuth.new)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const RepaintBoundary(child: ProfilePage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await captureScreen(tester, 'trav-profile-mobile-320');
      await tester.ensureVisible(find.text('Reset password'));
      await tester.tap(find.text('Reset password'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'one@example.com',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Profile settings stay usable with large phone text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await fontsAndPhoto(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(TestAuth.new)],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const RepaintBoundary(child: ProfilePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen(tester, 'trav-profile-large-text-320');
    await tester.scrollUntilVisible(find.text('Reset password'), 180);
    await tester.tap(find.text('Reset password'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Multiline chat keeps a compact send target and ignores empty messages',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await fontsAndPhoto(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: RepaintBoundary(child: AISearchPage(api: AIApi())),
          ),
        ),
      );
      final send = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Send message',
      );
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(find.text('Where shall we go?'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        'Plan a trip\nFrom Pune\nTo Goa\nA relaxed weekend',
      );
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(send).onPressed, isNotNull);
      expect(tester.getSize(send).height, 48);
      expect(tester.getSize(send).width, 48);
      await captureScreen(tester, 'trav-planner-composer-320');
      expect(tester.takeException(), isNull);
    },
  );
}
