import '../local/telemetry_store.dart';
import '../models/telemetry_reading.dart';
import '../remote/telemetry_api_client.dart';

class AquariumRepository {
  factory AquariumRepository({
    required String deviceId,
    required TelemetryStore localStore,
    required TelemetryApiClient apiClient,
  }) {
    return AquariumRepository._(deviceId, localStore, apiClient);
  }

  AquariumRepository._(this.deviceId, this._localStore, this._apiClient);

  final String deviceId;
  final TelemetryStore _localStore;
  final TelemetryApiClient _apiClient;

  bool get remoteConfigured => _apiClient.isConfigured;

  Future<List<TelemetryReading>> loadLatestCached() =>
      _localStore.getLatestReadings(deviceId);

  Future<List<TelemetryReading>> loadHistory({int limit = 200}) =>
      _localStore.getHistory(deviceId, limit: limit);

  Future<DateTime?> lastSuccessfulSync() =>
      _localStore.getLastSuccessfulSync(deviceId);

  Future<void> cacheReadings(List<TelemetryReading> readings) =>
      _localStore.saveReadings(readings);

  Future<void> recordSuccessfulSync(DateTime timestamp) =>
      _localStore.setLastSuccessfulSync(deviceId, timestamp);

  Future<List<TelemetryReading>> fetchRemoteLatest() =>
      _apiClient.fetchLatest(deviceId);

  Future<void> close() async {
    _apiClient.close();
    await _localStore.close();
  }
}
