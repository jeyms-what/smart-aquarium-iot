import 'package:flutter_test/flutter_test.dart';
import 'package:smart_aquarium_mobile/data/models/telemetry_reading.dart';
import 'package:smart_aquarium_mobile/features/care/fish_species.dart';

TelemetryReading _reading({
  required String sensorCode,
  required double value,
  required String unit,
  DateTime? measuredAt,
  String timeQuality = 'ntp_synced',
}) {
  final now = DateTime.now().toUtc();
  return TelemetryReading(
    eventId: 'test-event',
    deviceId: 'test-aquarium',
    sensorCode: sensorCode,
    value: value,
    unit: unit,
    isValid: true,
    measuredAt: measuredAt ?? now,
    receivedAt: now,
    timeQuality: timeQuality,
    sequenceNumber: 1,
  );
}

void main() {
  group('Species care profiles', () {
    test('Betta temperature inside the published guideline is within range', () {
      final betta = fishSpeciesById('betta_splendens')!;
      final reading = _reading(
        sensorCode: 'water_temperature',
        value: 26,
        unit: 'degC',
      );

      expect(
        betta.assessTemperature(reading).status,
        CareRangeStatus.withinGuideline,
      );
    });

    test('temperature in Fahrenheit is normalized to Celsius', () {
      final betta = fishSpeciesById('betta_splendens')!;
      final reading = _reading(
        sensorCode: 'water_temperature',
        value: 78.8,
        unit: 'degF',
      );

      final assessment = betta.assessTemperature(reading);
      expect(assessment.status, CareRangeStatus.withinGuideline);
      expect(assessment.value, closeTo(26, 0.05));
    });

    test('missing pH data is never treated as a healthy reading', () {
      final betta = fishSpeciesById('betta_splendens')!;

      expect(
        betta.assessPh(null).status,
        CareRangeStatus.notMeasured,
      );
    });

    test('stale sensor readings are not compared against care ranges', () {
      final betta = fishSpeciesById('betta_splendens')!;
      final reading = _reading(
        sensorCode: 'water_temperature',
        value: 26,
        unit: 'degC',
        measuredAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
      );

      expect(
        betta.assessTemperature(reading).status,
        CareRangeStatus.stale,
      );
    });

    test('uptime-only timestamps are marked as unverified', () {
      final betta = fishSpeciesById('betta_splendens')!;
      final reading = _reading(
        sensorCode: 'water_temperature',
        value: 26,
        unit: 'degC',
        timeQuality: 'uptime_only',
      );

      expect(
        betta.assessTemperature(reading).status,
        CareRangeStatus.timeUnverified,
      );
    });


    test('temperature above the guide is marked outside range', () {
      final betta = fishSpeciesById('betta_splendens')!;
      final reading = _reading(
        sensorCode: 'water_temperature',
        value: 30,
        unit: 'degC',
      );

      expect(
        betta.assessTemperature(reading).status,
        CareRangeStatus.aboveGuideline,
      );
    });

    test('unsupported temperature units are not compared', () {
      final betta = fishSpeciesById('betta_splendens')!;
      final reading = _reading(
        sensorCode: 'water_temperature',
        value: 25,
        unit: 'volts',
      );

      expect(
        betta.assessTemperature(reading).status,
        CareRangeStatus.unsupportedUnit,
      );
    });

    test('future device timestamps are not treated as current readings', () {
      final betta = fishSpeciesById('betta_splendens')!;
      final reading = _reading(
        sensorCode: 'water_temperature',
        value: 25,
        unit: 'degC',
        measuredAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      );

      expect(
        betta.assessTemperature(reading).status,
        CareRangeStatus.timeUnverified,
      );
    });

    test('neon tetra source note explains the group-level guidance', () {
      final neonTetra = fishSpeciesById('neon_tetra')!;

      expect(neonTetra.sourceNote, contains('group'));
      expect(neonTetra.sourceUrl, startsWith('https://'));
    });
  });
}
