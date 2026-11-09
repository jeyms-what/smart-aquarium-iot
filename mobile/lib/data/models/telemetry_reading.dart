class TelemetryReading {
  const TelemetryReading({
    required this.eventId,
    required this.deviceId,
    required this.sensorCode,
    required this.value,
    required this.unit,
    required this.isValid,
    required this.measuredAt,
    required this.receivedAt,
    required this.timeQuality,
    required this.sequenceNumber,
  });

  final String eventId;
  final String deviceId;
  final String sensorCode;
  final double? value;
  final String unit;
  final bool isValid;
  final DateTime measuredAt;
  final DateTime receivedAt;
  final String timeQuality;
  final int sequenceNumber;

  bool get hasUsableValue => isValid && value != null && value!.isFinite;

  String get displayName => switch (sensorCode) {
        'water_temperature' => 'Water temperature',
        'water_level' => 'Water level',
        'turbidity' => 'Turbidity',
        _ => sensorCode.replaceAll('_', ' '),
      };

  String get displayUnit => switch (unit) {
        'degC' => '°C',
        'degF' => '°F',
        'cm' => 'cm',
        'mm' => 'mm',
        'ntu' => 'NTU',
        'raw_adc' => 'raw ADC',
        _ => unit,
      };

  String get formattedValue {
    if (!hasUsableValue) return '—';
    final digits = switch (sensorCode) {
      'water_temperature' => 1,
      'water_level' => 1,
      _ => 2,
    };
    return value!.toStringAsFixed(digits);
  }

  bool isStale({DateTime? now, Duration threshold = const Duration(minutes: 2)}) {
    // Uptime-only timestamps are not reliable wall-clock values, so age cannot
    // be calculated safely for these records.
    if (timeQuality == 'uptime_only') return false;
    final reference = now ?? DateTime.now();
    final age = reference.difference(measuredAt.toLocal());
    return !age.isNegative && age > threshold;
  }

  factory TelemetryReading.fromApiJson(
    Map<String, dynamic> json, {
    required String fallbackDeviceId,
  }) {
    final rawValue = json['measurement_value'];
    final parsedValue = rawValue == null
        ? null
        : rawValue is num
            ? rawValue.toDouble()
            : double.tryParse(rawValue.toString());

    final rawMeasuredAt = json['measured_at'];
    final rawReceivedAt = json['received_at'];
    final rawSequence = json['sequence_number'];

    if (json['event_id'] is! String ||
        json['sensor_code'] is! String ||
        json['measurement_unit'] is! String ||
        rawMeasuredAt is! String ||
        rawReceivedAt is! String ||
        rawSequence == null) {
      throw const FormatException('Telemetry record is missing required fields.');
    }

    final measuredAt = DateTime.tryParse(rawMeasuredAt);
    final receivedAt = DateTime.tryParse(rawReceivedAt);
    final sequenceNumber = rawSequence is num
        ? rawSequence.toInt()
        : int.tryParse(rawSequence.toString());

    if (measuredAt == null || receivedAt == null || sequenceNumber == null) {
      throw const FormatException('Telemetry record contains an invalid timestamp or sequence.');
    }

    final timeQuality = (json['time_quality'] as String?) ?? 'uptime_only';
    const supportedTimeQualities = {
      'ntp_synced',
      'rtc_synced',
      'rtc_estimated',
      'uptime_only',
    };
    if (!supportedTimeQualities.contains(timeQuality)) {
      throw const FormatException('Telemetry record contains an unsupported time-quality value.');
    }

    final isValid = json['is_valid'] == true &&
        parsedValue != null &&
        parsedValue.isFinite;

    return TelemetryReading(
      eventId: json['event_id'] as String,
      deviceId: (json['device_id'] as String?) ?? fallbackDeviceId,
      sensorCode: json['sensor_code'] as String,
      value: parsedValue?.isFinite == true ? parsedValue : null,
      unit: json['measurement_unit'] as String,
      isValid: isValid,
      measuredAt: measuredAt.toUtc(),
      receivedAt: receivedAt.toUtc(),
      timeQuality: timeQuality,
      sequenceNumber: sequenceNumber,
    );
  }

  factory TelemetryReading.fromDatabaseMap(Map<String, Object?> row) {
    final rawValue = row['measurement_value'];
    final value = rawValue == null ? null : (rawValue as num).toDouble();

    return TelemetryReading(
      eventId: row['event_id'] as String,
      deviceId: row['device_id'] as String,
      sensorCode: row['sensor_code'] as String,
      value: value,
      unit: row['measurement_unit'] as String,
      isValid: row['is_valid'] == 1 && value != null && value.isFinite,
      measuredAt: DateTime.parse(row['measured_at'] as String).toUtc(),
      receivedAt: DateTime.parse(row['received_at'] as String).toUtc(),
      timeQuality: row['time_quality'] as String,
      sequenceNumber: row['sequence_number'] as int,
    );
  }

  Map<String, Object?> toDatabaseMap() => {
        'event_id': eventId,
        'device_id': deviceId,
        'sensor_code': sensorCode,
        'measurement_value': value,
        'measurement_unit': unit,
        'is_valid': isValid ? 1 : 0,
        'measured_at': measuredAt.toUtc().toIso8601String(),
        'received_at': receivedAt.toUtc().toIso8601String(),
        'time_quality': timeQuality,
        'sequence_number': sequenceNumber,
      };
}
