import 'package:flutter_test/flutter_test.dart';
import 'package:smart_aquarium_mobile/data/models/telemetry_reading.dart';

void main() {
  group('TelemetryReading.fromApiJson', () {
    test('parses a valid server telemetry record', () {
      final reading = TelemetryReading.fromApiJson(
        {
          'event_id': '11111111-1111-4111-8111-111111111111',
          'device_id': 'aquarium_001',
          'sensor_code': 'water_temperature',
          'measurement_value': 25.4,
          'measurement_unit': 'degC',
          'is_valid': true,
          'measured_at': '2026-11-09T01:00:00.000Z',
          'received_at': '2026-11-09T01:00:02.000Z',
          'time_quality': 'ntp_synced',
          'sequence_number': 12,
        },
        fallbackDeviceId: 'aquarium_001',
      );

      expect(reading.hasUsableValue, isTrue);
      expect(reading.value, 25.4);
      expect(reading.displayUnit, '°C');
      expect(reading.sequenceNumber, 12);
    });

    test('does not treat invalid or null sensor data as a measurement', () {
      final reading = TelemetryReading.fromApiJson(
        {
          'event_id': '22222222-2222-4222-8222-222222222222',
          'device_id': 'aquarium_001',
          'sensor_code': 'turbidity',
          'measurement_value': null,
          'measurement_unit': 'raw_adc',
          'is_valid': false,
          'measured_at': '2026-11-09T01:00:00.000Z',
          'received_at': '2026-11-09T01:00:02.000Z',
          'time_quality': 'rtc_synced',
          'sequence_number': 13,
        },
        fallbackDeviceId: 'aquarium_001',
      );

      expect(reading.hasUsableValue, isFalse);
      expect(reading.formattedValue, '—');
    });

    test('rejects records missing identity or timing fields', () {
      expect(
        () => TelemetryReading.fromApiJson(
          {'sensor_code': 'water_level'},
          fallbackDeviceId: 'aquarium_001',
        ),
        throwsFormatException,
      );
    });
  });
}
