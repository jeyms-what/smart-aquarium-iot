import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_aquarium_mobile/app.dart';
import 'package:smart_aquarium_mobile/features/care/fish_care_profile_store.dart';

void main() {
  testWidgets('dashboard shows unavailable values until telemetry exists', (tester) async {
    await tester.pumpWidget(const SmartAquariumApp());
    await tester.pumpAndSettle();

    expect(find.text('Remote API not configured'), findsOneWidget);
    expect(find.text('No reading °C'), findsOneWidget);

    // The dashboard is a lazy sliver list, so scroll to build the recommendation
    // panel before asserting the care entry point.
    await tester.scrollUntilVisible(
      find.text('Species-specific fish care'),
      250,
      maxScrolls: 10,
    );
    expect(find.text('Species-specific fish care'), findsOneWidget);
  });

  testWidgets('history navigation shows an empty local-history state', (tester) async {
    await tester.pumpWidget(const SmartAquariumApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-history')));
    await tester.pumpAndSettle();

    expect(find.text('No historical records'), findsOneWidget);
  });

  testWidgets('fish care profile can be selected and persisted', (tester) async {
    final profileStore = InMemoryFishCareProfileStore();
    await tester.pumpWidget(
      SmartAquariumApp(fishCareProfileStore: profileStore),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-care')));
    await tester.pumpAndSettle();

    expect(find.text('Care for your fish'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('fish-species-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Betta · Betta splendens').last);
    await tester.pumpAndSettle();

    expect(find.text('Betta'), findsOneWidget);
    expect(profileStore.selectedSpeciesId, 'betta_splendens');
    await tester.scrollUntilVisible(
      find.text('Species care recommendations'),
      220,
      maxScrolls: 10,
    );
    expect(find.text('Species care recommendations'), findsOneWidget);
    expect(find.text('Not measured'), findsWidgets);
  });

}
