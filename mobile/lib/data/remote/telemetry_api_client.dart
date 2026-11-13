import 'dart:convert';
import 'dart:io';

import '../../core/config/app_config.dart';
import '../models/device_command.dart';
import '../models/telemetry_reading.dart';

class TelemetryApiException implements Exception {
  const TelemetryApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class TelemetryApiClient {
  TelemetryApiClient({HttpClient? httpClient}) : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;

  bool get isConfigured => AppConfig.remoteApiEnabled;
  bool get commandControlEnabled => AppConfig.remoteCommandControlEnabled;

  Uri _deviceUri(String deviceId, String resource) {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(deviceId)) {
      throw const TelemetryApiException('Device identifier contains unsupported characters.');
    }

    final base = AppConfig.apiBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/api/v1/devices/$deviceId/$resource');
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw const TelemetryApiException('API URL must use HTTP or HTTPS.');
    }

    const allowedDevelopmentHosts = {'127.0.0.1', 'localhost', '10.0.2.2'};
    if (!allowedDevelopmentHosts.contains(uri.host)) {
      throw const TelemetryApiException(
        'The development API token is restricted to localhost. Use proper user authentication before connecting to a remote host.',
      );
    }
    return uri;
  }

  Future<Map<String, dynamic>> _requestJson({
    required String method,
    required Uri uri,
    required Set<int> acceptedStatusCodes,
    Object? body,
  }) async {
    if (!isConfigured) {
      throw const TelemetryApiException('The local development API is not configured.');
    }

    final request = switch (method) {
      'GET' => await _httpClient.getUrl(uri).timeout(const Duration(seconds: 8)),
      'POST' => await _httpClient.postUrl(uri).timeout(const Duration(seconds: 8)),
      _ => throw ArgumentError.value(method, 'method', 'Unsupported API method.'),
    };

    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer ${AppConfig.developmentBearerToken}',
    );
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }

    final response = await request.close().timeout(const Duration(seconds: 10));
    final responseBody = await utf8.decoder
        .bind(response)
        .join()
        .timeout(const Duration(seconds: 10));

    if (!acceptedStatusCodes.contains(response.statusCode)) {
      var detail = 'HTTP ${response.statusCode}.';
      try {
        final decodedError = jsonDecode(responseBody);
        if (decodedError is Map && decodedError['error'] is String) {
          detail = decodedError['error'] as String;
        }
      } catch (_) {
        // Keep the HTTP status when the server does not return JSON.
      }
      throw TelemetryApiException('API request failed: $detail');
    }

    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw const TelemetryApiException('API returned an unexpected response format.');
    }
    return decoded;
  }

  Future<List<TelemetryReading>> fetchLatest(String deviceId) async {
    final uri = _deviceUri(deviceId, 'telemetry/latest');
    final decoded = await _requestJson(
      method: 'GET',
      uri: uri,
      acceptedStatusCodes: {HttpStatus.ok},
    );

    final rawReadings = decoded['readings'];
    if (decoded['device_id'] != deviceId || rawReadings is! List) {
      throw const TelemetryApiException('API response does not match the requested aquarium.');
    }

    try {
      final readings = <TelemetryReading>[];
      for (final rawReading in rawReadings) {
        if (rawReading is! Map<String, dynamic>) {
          throw const FormatException('A telemetry array item is not an object.');
        }
        final reading = TelemetryReading.fromApiJson(
          rawReading,
          fallbackDeviceId: deviceId,
        );
        if (reading.deviceId != deviceId) {
          throw const FormatException('A telemetry record belongs to a different device.');
        }
        readings.add(reading);
      }
      return readings;
    } on FormatException catch (error) {
      throw TelemetryApiException('API returned invalid telemetry: ${error.message}');
    } on TypeError catch (_) {
      throw const TelemetryApiException('API returned telemetry with incorrect field types.');
    }
  }

  Future<DeviceCommand> submitCommand({
    required String deviceId,
    required String command,
    String? requestedState,
    int expiresInSeconds = 30,
  }) async {
    if (!commandControlEnabled) {
      throw const TelemetryApiException(
        'Device commands are disabled. They may only be enabled after the ESP32 command handler and physical feedback have been tested.',
      );
    }

    if (command == 'SET_PUMP' && requestedState != 'ON' && requestedState != 'OFF') {
      throw const TelemetryApiException('Pump commands require a target state of ON or OFF.');
    }
    if (command == 'FEED_NOW' && requestedState != null) {
      throw const TelemetryApiException('FEED_NOW does not accept a requested state.');
    }
    if (command != 'SET_PUMP' && command != 'FEED_NOW') {
      throw const TelemetryApiException('Unsupported device command.');
    }
    if (expiresInSeconds < 5 || expiresInSeconds > 60) {
      throw const TelemetryApiException('Command expiry must be between 5 and 60 seconds.');
    }

    final requestedAt = DateTime.now().toUtc();
    final uri = _deviceUri(deviceId, 'commands');
    final response = await _requestJson(
      method: 'POST',
      uri: uri,
      acceptedStatusCodes: {HttpStatus.accepted},
      body: {
        'command': command,
        if (requestedState != null) 'requested_state': requestedState,
        'expires_in_seconds': expiresInSeconds,
      },
    );

    try {
      return DeviceCommand.fromPublishedResponse(
        json: response,
        deviceId: deviceId,
        command: command,
        requestedState: requestedState,
        requestedAt: requestedAt,
      );
    } on FormatException catch (error) {
      throw TelemetryApiException('Backend returned an invalid command response: ${error.message}');
    }
  }

  Future<DeviceCommand> fetchCommandStatus({
    required String deviceId,
    required String commandId,
  }) async {
    if (!RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(commandId)) {
      throw const TelemetryApiException('Command identifier is invalid.');
    }
    final uri = _deviceUri(deviceId, 'commands/$commandId');
    final response = await _requestJson(
      method: 'GET',
      uri: uri,
      acceptedStatusCodes: {HttpStatus.ok},
    );

    try {
      final command = DeviceCommand.fromStatusJson(response);
      if (command.deviceId != deviceId || command.commandId != commandId) {
        throw const FormatException('Command status does not match the requested command.');
      }
      return command;
    } on FormatException catch (error) {
      throw TelemetryApiException('Backend returned an invalid command status: ${error.message}');
    } on TypeError catch (_) {
      throw const TelemetryApiException('Backend returned command status with incorrect field types.');
    }
  }

  void close() => _httpClient.close(force: true);
}
