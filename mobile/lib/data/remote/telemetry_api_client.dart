import 'dart:convert';
import 'dart:io';

import '../../core/config/app_config.dart';
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

  Future<List<TelemetryReading>> fetchLatest(String deviceId) async {
    if (!isConfigured) {
      throw const TelemetryApiException('The local development API is not configured.');
    }

    if (!RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(deviceId)) {
      throw const TelemetryApiException('Device identifier contains unsupported characters.');
    }

    final base = AppConfig.apiBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/api/v1/devices/$deviceId/telemetry/latest');
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw const TelemetryApiException('API URL must use HTTP or HTTPS.');
    }
    const allowedDevelopmentHosts = {'127.0.0.1', 'localhost', '10.0.2.2'};
    if (!allowedDevelopmentHosts.contains(uri.host)) {
      throw const TelemetryApiException(
        'The development API token is restricted to localhost. Use a proper user-authentication flow before connecting to a remote host.',
      );
    }

    final request = await _httpClient.getUrl(uri).timeout(const Duration(seconds: 8));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer ${AppConfig.developmentBearerToken}',
    );

    final response = await request.close().timeout(const Duration(seconds: 10));
    final body = await utf8.decoder.bind(response).join().timeout(const Duration(seconds: 10));

    if (response.statusCode != HttpStatus.ok) {
      throw TelemetryApiException('API request failed with HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const TelemetryApiException('API returned an unexpected response format.');
    }

    final responseDeviceId = decoded['device_id'];
    final rawReadings = decoded['readings'];
    if (responseDeviceId != deviceId || rawReadings is! List) {
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

  void close() => _httpClient.close(force: true);
}
