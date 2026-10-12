import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/core/theme/app_theme.dart';
import 'package:trav_planner/features/profile/data/travel_preferences_api.dart';
import 'package:trav_planner/features/profile/presentation/pages/travel_preferences_page.dart';
import 'package:trav_planner/features/auth/presentation/providers/auth_provider.dart';
import 'saved_places_test.dart' show TestAuth;

class PreferencesApi extends TravelPreferencesApi {
  Map<String, dynamic> data = {
    'interests': 'Nature',
    'budget_level': 'Comfort',
    'other_preferences': 'Quiet mornings',
  };
  bool fail = false;
  @override
  Future<Map<String, dynamic>> load() async => Map.of(data);
  @override
  Future<void> save(Map<String, dynamic> value) async {
    if (fail) throw Exception('offline');
    data = Map.of(value);
  }
}

void main() {
  testWidgets(
    'Preferences load, save interests and explicit mood, reopen, and retain failed drafts',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = PreferencesApi();
      Future<void> show() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(TestAuth.new),
              travelPreferencesApiProvider.overrideWithValue(api),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const TravelPreferencesPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show();
      final nature = find.widgetWithText(FilterChip, 'Nature');
      expect(tester.widget<FilterChip>(nature).selected, isTrue);
      await tester.tap(find.widgetWithText(FilterChip, 'Adventure'));
      await tester.ensureVisible(
        find.widgetWithText(ChoiceChip, 'Adventurous'),
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Adventurous'));
      await tester.ensureVisible(find.text('Save preferences'));
      await tester.tap(find.text('Save preferences'));
      await tester.pumpAndSettle();
      expect(api.data['interests'], contains('Adventure'));
      final other = jsonDecode(api.data['other_preferences']);
      expect(other['mood'], 'Adventurous');
      expect(other['notes'], 'Quiet mornings');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await show();
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Adventure'))
            .selected,
        isTrue,
      );
      api.fail = true;
      await tester.tap(find.widgetWithText(FilterChip, 'Food'));
      await tester.ensureVisible(find.text('Save preferences'));
      await tester.tap(find.text('Save preferences'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Couldn’t save preferences. Your choices are still here—try again.',
        ),
        findsOneWidget,
      );
      expect(api.data['interests'], isNot(contains('Food')));
      expect(tester.takeException(), isNull);
    },
  );
}
