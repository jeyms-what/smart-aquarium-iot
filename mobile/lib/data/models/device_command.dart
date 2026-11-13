class DeviceCommand {
  const DeviceCommand({
    required this.commandId,
    required this.deviceId,
    required this.command,
    required this.requestedState,
    required this.status,
    required this.requestedAt,
    required this.expiresAt,
    required this.acknowledgedAt,
    required this.stateVerified,
    this.message,
  });

  final String commandId;
  final String deviceId;
  final String command;
  final String? requestedState;
  final String status;
  final DateTime requestedAt;
  final DateTime expiresAt;
  final DateTime? acknowledgedAt;
  final bool stateVerified;
  final String? message;

  bool get hasDeviceAcknowledgement =>
      status == 'executed' || status == 'rejected' || status == 'failed';

  bool get isVerifiedSuccess => status == 'executed' && stateVerified;

  bool get isTerminal => hasDeviceAcknowledgement || status == 'publish_failed';

  bool isExpiredAt(DateTime now) => !isTerminal && now.isAfter(expiresAt);

  String statusLabelAt(DateTime now) {
    if (isVerifiedSuccess) return 'Executed and state verified';
    if (status == 'executed') return 'Acknowledged; physical state not verified';
    if (status == 'rejected') return 'Rejected by device';
    if (status == 'failed') return 'Execution failed';
    if (status == 'publish_failed') return 'Could not publish command';
    if (isExpiredAt(now)) return 'No acknowledgement before command expiry';
    if (status == 'queued') return 'Queued by backend';
    return 'Published; awaiting device acknowledgement';
  }

  factory DeviceCommand.fromPublishedResponse({
    required Map<String, dynamic> json,
    required String deviceId,
    required String command,
    required String? requestedState,
    required DateTime requestedAt,
  }) {
    final commandId = json['command_id'];
    final status = json['status'];
    final rawExpiresAt = json['expires_at'];

    if (commandId is! String || status is! String || rawExpiresAt is! String) {
      throw const FormatException('Command response is missing required fields.');
    }
    final expiresAt = DateTime.tryParse(rawExpiresAt);
    if (expiresAt == null) {
      throw const FormatException('Command response contains an invalid expiry time.');
    }

    return DeviceCommand(
      commandId: commandId,
      deviceId: deviceId,
      command: command,
      requestedState: requestedState,
      status: status,
      requestedAt: requestedAt.toUtc(),
      expiresAt: expiresAt.toUtc(),
      acknowledgedAt: null,
      stateVerified: false,
      message: json['message'] is String ? json['message'] as String : null,
    );
  }

  factory DeviceCommand.fromStatusJson(Map<String, dynamic> json) {
    final commandId = json['command_id'];
    final deviceId = json['device_id'];
    final command = json['command'];
    final status = json['status'];
    final rawRequestedAt = json['requested_at'];
    final rawExpiresAt = json['expires_at'];

    if (commandId is! String ||
        deviceId is! String ||
        command is! String ||
        status is! String ||
        rawRequestedAt is! String ||
        rawExpiresAt is! String) {
      throw const FormatException('Command status is missing required fields.');
    }

    final requestedAt = DateTime.tryParse(rawRequestedAt);
    final expiresAt = DateTime.tryParse(rawExpiresAt);
    if (requestedAt == null || expiresAt == null) {
      throw const FormatException('Command status contains an invalid timestamp.');
    }

    final rawAcknowledgedAt = json['acknowledged_at'];
    final acknowledgedAt = rawAcknowledgedAt is String
        ? DateTime.tryParse(rawAcknowledgedAt)
        : null;

    return DeviceCommand(
      commandId: commandId,
      deviceId: deviceId,
      command: command,
      requestedState: json['requested_state'] as String?,
      status: status,
      requestedAt: requestedAt.toUtc(),
      expiresAt: expiresAt.toUtc(),
      acknowledgedAt: acknowledgedAt?.toUtc(),
      stateVerified: json['state_verified'] == true,
    );
  }
}
