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

    test('formats TDS telemetry with its reported ppm unit', () {
      final reading = TelemetryReading.fromApiJson(
        {
          'event_id': '33333333-3333-4333-8333-333333333333',
          'device_id': 'aquarium_001',
          'sensor_code': 'tds',
          'measurement_value': 185.0,
          'measurement_unit': 'ppm',
          'is_valid': true,
          'measured_at': '2026-11-09T01:00:00.000Z',
          'received_at': '2026-11-09T01:00:02.000Z',
          'time_quality': 'ntp_synced',
          'sequence_number': 14,
        },
        fallbackDeviceId: 'aquarium_001',
      );

      expect(reading.displayName, 'TDS');
      expect(reading.displayUnit, 'ppm');
      expect(reading.formattedValue, '185');
    });

    test('labels pH channel aliases consistently', () {
      final reading = TelemetryReading.fromApiJson(
        {
          'event_id': '44444444-4444-4444-8444-444444444444',
          'device_id': 'aquarium_001',
          'sensor_code': 'water_ph',
          'measurement_value': 7.25,
          'measurement_unit': 'pH',
          'is_valid': true,
          'measured_at': '2026-11-09T01:00:00.000Z',
          'received_at': '2026-11-09T01:00:02.000Z',
          'time_quality': 'ntp_synced',
          'sequence_number': 15,
        },
        fallbackDeviceId: 'aquarium_001',
      );

      expect(reading.displayName, 'pH');
      expect(reading.displayUnit, 'pH');
      expect(reading.formattedValue, '7.25');
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
