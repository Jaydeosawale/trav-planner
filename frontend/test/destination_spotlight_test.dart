import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/core/theme/app_theme.dart';
import 'package:trav_planner/features/home/presentation/widgets/destination_spotlight.dart';

void main() {
  Future<void> show(WidgetTester tester, {bool reduced = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Scaffold(
            body: DestinationSpotlight(banners: const [], onSearch: (_) {}),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'Slideshow advances every five seconds and wraps with dots only',
    (tester) async {
      await show(tester);
      expect(find.text('Bali, Indonesia'), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
      expect(find.byType(TextField), findsNothing);
      for (final place in ['Goa, India', 'Paris, France', 'Bali, Indonesia']) {
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        expect(find.text(place), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Reduced motion and keyboard focus keep destination steady', (
    tester,
  ) async {
    await show(tester, reduced: true);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Bali, Indonesia'), findsOneWidget);
    await show(tester);
    Focus.of(tester.element(find.text('Bali, Indonesia'))).requestFocus();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Bali, Indonesia'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Top label opens visible destination; search stays separate', (
    tester,
  ) async {
    final opened = <String>[];
    var searches = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: DestinationSpotlight(
              banners: const [],
              onSearch: (_) {},
              onOpen: (label, slug, redirect) => opened.add('$label/$slug'),
              search: TextField(readOnly: true, onTap: () => searches++),
            ),
          ),
        ),
      ),
    );
    final top = tester.getTopLeft(find.byType(DestinationSpotlight)).dy;
    expect(
      tester.getTopLeft(find.text('Bali, Indonesia')).dy - top,
      lessThan(40),
    );
    await tester.tapAt(tester.getCenter(find.text('Bali, Indonesia')));
    expect(opened, ['Bali, Indonesia/bali']);
    await tester.tap(find.byType(TextField));
    expect(searches, 1);
    expect(opened.length, 1);
    await tester.drag(find.byType(PageView), const Offset(-390, 0));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.text('Goa, India')));
    expect(opened.last, 'Goa, India/goa');
    await tester.pumpWidget(const SizedBox());
  });
}
