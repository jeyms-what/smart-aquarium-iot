import 'package:flutter/foundation.dart';

/// Build-time configuration for the local development API.
///
/// The development bearer token is intentionally accepted only in debug mode.
/// It is a temporary local-development mechanism, not production authentication.
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'AQUARIUM_API_BASE_URL',
    defaultValue: '',
  );

  static const String developmentBearerToken = String.fromEnvironment(
    'AQUARIUM_API_DEV_TOKEN',
    defaultValue: '',
  );

  static const String deviceId = String.fromEnvironment(
    'AQUARIUM_DEVICE_ID',
    defaultValue: 'aquarium_001',
  );

  static bool get remoteApiEnabled =>
      kDebugMode &&
      apiBaseUrl.trim().isNotEmpty &&
      developmentBearerToken.trim().length >= 32;

  static String get apiConfigurationLabel {
    if (!kDebugMode) {
      return 'Remote API disabled in release builds until user authentication is implemented.';
    }
    if (apiBaseUrl.trim().isEmpty) {
      return 'Not configured. Set AQUARIUM_API_BASE_URL for local development.';
    }
    if (developmentBearerToken.trim().length < 32) {
      return 'Not configured. A development API token of at least 32 characters is required.';
    }
    return 'Configured for local development only.';
  }
}
