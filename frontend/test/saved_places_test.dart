import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/core/theme/app_theme.dart';
import 'package:trav_planner/features/auth/data/models/user_model.dart';
import 'package:trav_planner/features/auth/presentation/providers/auth_provider.dart';
import 'package:trav_planner/features/destinations/data/place.dart';
import 'package:trav_planner/features/destinations/data/places_provider.dart';
import 'package:trav_planner/features/saved/data/saved_places_api.dart';
import 'package:trav_planner/features/saved/presentation/pages/saved_page.dart';
import 'package:trav_planner/features/saved/presentation/saved_places_provider.dart';

AuthState account(String id) => AuthState.authenticated(
  user: UserModel(
    id: id,
    email: '$id@example.com',
    fullName: id,
    isActive: true,
    createdAt: DateTime(2026),
    role: 'user',
  ),
);

class TestAuth extends AuthNotifier {
  @override
  AuthState build() => account('one');
  void switchAccount(String id) => state = account(id);
}

const place = TravelPlace(
  id: 'landmark',
  cityId: 'city',
  name: 'Historic landmark',
  type: 'heritage',
  description: 'A place worth visiting',
);

class TestApi extends SavedPlacesApi {
  String owner = 'one';
  final records = <String, List<TravelPlace>>{};
  bool fail = false;
  Completer<void>? gate;
  int writes = 0;
  @override
  Future<List<TravelPlace>> load() async => List.of(records[owner] ?? []);
  @override
  Future<void> save(String id) async {
    writes++;
    await gate?.future;
    if (fail) throw Exception('offline');
    records[owner] = [place];
  }

  @override
  Future<void> remove(String id) async {
    if (fail) throw Exception('offline');
    records[owner] = [];
  }
}

void main() {
  ProviderContainer container(TestApi api) => ProviderContainer(
    overrides: [
      authProvider.overrideWith(TestAuth.new),
      savedPlacesApiProvider.overrideWithValue(api),
    ],
  );

  test(
    'saved places persist across sessions and isolate account changes',
    () async {
      final api = TestApi();
      final first = container(api);
      await first.read(savedPlacesProvider.future);
      await first.read(savedPlacesProvider.notifier).toggle(place);
      expect(first.read(savedPlacesProvider).requireValue.single.id, place.id);
      first.dispose();
      final next = container(api);
      expect((await next.read(savedPlacesProvider.future)).single.id, place.id);
      api.owner = 'two';
      (next.read(authProvider.notifier) as TestAuth).switchAccount('two');
      expect(await next.read(savedPlacesProvider.future), isEmpty);
      api.owner = 'one';
      (next.read(authProvider.notifier) as TestAuth).switchAccount('one');
      expect((await next.read(savedPlacesProvider.future)).length, 1);
      await next.read(savedPlacesProvider.notifier).toggle(place);
      expect(next.read(savedPlacesProvider).requireValue, isEmpty);
      next.dispose();
    },
  );

  test(
    'failed saves keep state and repeated taps do not duplicate writes',
    () async {
      final api = TestApi()..gate = Completer<void>();
      final scope = container(api);
      await scope.read(savedPlacesProvider.future);
      final saving = scope.read(savedPlacesProvider.notifier).toggle(place);
      await scope.read(savedPlacesProvider.notifier).toggle(place);
      expect(api.writes, 1);
      api.gate!.complete();
      await saving;
      api.fail = true;
      await expectLater(
        scope.read(savedPlacesProvider.notifier).toggle(place),
        throwsException,
      );
      expect(scope.read(savedPlacesProvider).requireValue.single.id, place.id);
      expect(scope.read(savingPlacesProvider), isEmpty);
      scope.dispose();
    },
  );

  for (final width in [320.0, 1100.0]) {
    testWidgets('Saved list opens place details and removes at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
        for (final family in ['Manrope', 'DM Sans', 'Inter']) {
          final fonts = FontLoader(family);
          for (final weight in [400, 500, 600, 700, 800]) {
            fonts.addFont(
              rootBundle.load(
                'assets/fonts/${family == 'DM Sans' ? 'DMSans' : family}-$weight.ttf',
              ),
            );
          }
          await fonts.load();
        }
      });
      final api = TestApi()..records['one'] = [place];
      final key = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(TestAuth.new),
            savedPlacesApiProvider.overrideWithValue(api),
            cityPlacesProvider('city').overrideWith((ref) async => [place]),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: RepaintBoundary(key: key, child: const SavedPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(place.name), findsOneWidget);
      expect(tester.takeException(), isNull);
      const output = String.fromEnvironment('TRAV_SCREENSHOT_DIR');
      if (output.isNotEmpty) {
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '$output/trav-saved-${width.toInt()}.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.text(place.name));
      await tester.pumpAndSettle();
      expect(find.text(place.description!), findsOneWidget);
      await tester.tap(find.text('Remove from Saved'));
      await tester.pumpAndSettle();
      expect(api.records['one'], isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}
