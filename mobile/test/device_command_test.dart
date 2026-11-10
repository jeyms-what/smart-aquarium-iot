import 'package:flutter_test/flutter_test.dart';
import 'package:smart_aquarium_mobile/data/models/device_command.dart';

void main() {
  group('DeviceCommand', () {
    test('does not call a published command successful', () {
      final command = DeviceCommand.fromPublishedResponse(
        json: {
          'command_id': '11111111-1111-4111-8111-111111111111',
          'status': 'published_unconfirmed',
          'message': 'Command was published.',
          'expires_at': '2026-11-10T10:00:30.000Z',
        },
        deviceId: 'aquarium_001',
        command: 'SET_PUMP',
        requestedState: 'ON',
        requestedAt: DateTime.parse('2026-11-10T10:00:00.000Z'),
      );

      expect(command.status, 'published_unconfirmed');
      expect(command.isVerifiedSuccess, isFalse);
      expect(command.hasDeviceAcknowledgement, isFalse);
    });

    test('requires state verification before showing successful execution', () {
      final command = DeviceCommand.fromStatusJson({
        'command_id': '22222222-2222-4222-8222-222222222222',
        'device_id': 'aquarium_001',
        'command': 'SET_PUMP',
        'requested_state': 'OFF',
        'status': 'executed',
        'requested_at': '2026-11-10T10:00:00.000Z',
        'expires_at': '2026-11-10T10:00:30.000Z',
        'acknowledged_at': '2026-11-10T10:00:02.000Z',
        'state_verified': false,
        'result': {'status': 'executed'},
      });

      expect(command.hasDeviceAcknowledgement, isTrue);
      expect(command.isVerifiedSuccess, isFalse);
      expect(
        command.statusLabelAt(DateTime.parse('2026-11-10T10:00:05.000Z')),
        'Acknowledged; physical state not verified',
      );
    });

    test('recognizes a verified device result', () {
      final command = DeviceCommand.fromStatusJson({
        'command_id': '33333333-3333-4333-8333-333333333333',
        'device_id': 'aquarium_001',
        'command': 'SET_PUMP',
        'requested_state': 'ON',
        'status': 'executed',
        'requested_at': '2026-11-10T10:00:00.000Z',
        'expires_at': '2026-11-10T10:00:30.000Z',
        'acknowledged_at': '2026-11-10T10:00:02.000Z',
        'state_verified': true,
      });

      expect(command.isVerifiedSuccess, isTrue);
      expect(
        command.statusLabelAt(DateTime.parse('2026-11-10T10:00:05.000Z')),
        'Executed and state verified',
      );
    });

    test('marks an unacknowledged command expired locally', () {
      final command = DeviceCommand.fromStatusJson({
        'command_id': '44444444-4444-4444-8444-444444444444',
        'device_id': 'aquarium_001',
        'command': 'FEED_NOW',
        'requested_state': null,
        'status': 'published_unconfirmed',
        'requested_at': '2026-11-10T10:00:00.000Z',
        'expires_at': '2026-11-10T10:00:30.000Z',
        'acknowledged_at': null,
        'state_verified': false,
      });

      expect(command.isExpiredAt(DateTime.parse('2026-11-10T10:00:31.000Z')), isTrue);
    });
  });
}
