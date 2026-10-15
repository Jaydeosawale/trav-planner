import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/core/widgets/place_source_credit.dart';

void main() {
  testWidgets(
    'source credit appears only for Geoapify results and fits a phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlaceSourceCredit(
              data: [
                {'visiting_notes': 'Powered by Geoapify · OSM'},
              ],
            ),
          ),
        ),
      );
      expect(find.text('Powered by Geoapify'), findsOneWidget);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlaceSourceCredit(
              data: [
                {'visiting_notes': 'Wikidata'},
              ],
            ),
          ),
        ),
      );
      expect(find.byType(TextButton), findsNothing);
    },
  );
}
