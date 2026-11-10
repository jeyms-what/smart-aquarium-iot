import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_aquarium_mobile/app.dart';

void main() {
  testWidgets('dashboard shows unavailable values until telemetry exists', (tester) async {
    await tester.pumpWidget(const SmartAquariumApp());
    await tester.pumpAndSettle();

    expect(find.text('Remote API not configured'), findsOneWidget);
    expect(find.text('No reading °C'), findsOneWidget);

    // The dashboard is a lazy sliver list, so scroll to build the recommendation
    // panel before asserting its empty state.
    await tester.scrollUntilVisible(
      find.text('No recommendation available'),
      250,
      maxScrolls: 10,
    );
    expect(find.text('No recommendation available'), findsOneWidget);
  });

  testWidgets('history navigation shows an empty local-history state', (tester) async {
    await tester.pumpWidget(const SmartAquariumApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.show_chart));
    await tester.pumpAndSettle();

    expect(find.text('No historical records'), findsOneWidget);
  });
}
