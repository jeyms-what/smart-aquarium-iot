import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/telemetry_reading.dart';
import '../../data/repositories/aquarium_repository.dart';

enum MonitoringSource {
  notConfigured,
  remote,
  cached,
  offline,
}

class MonitoringSnapshot {
  const MonitoringSnapshot({
    this.readings = const [],
    this.source = MonitoringSource.notConfigured,
    this.lastCheckedAt,
    this.lastSuccessfulSyncAt,
    this.message = 'No telemetry has been received.',
  });

  final List<TelemetryReading> readings;
  final MonitoringSource source;
  final DateTime? lastCheckedAt;
  final DateTime? lastSuccessfulSyncAt;
  final String message;

  TelemetryReading? readingFor(String sensorCode) {
    for (final reading in readings) {
      if (reading.sensorCode == sensorCode) return reading;
    }
    return null;
  }
}

class MonitoringController extends ChangeNotifier {
  factory MonitoringController({AquariumRepository? repository}) =>
      MonitoringController._(repository);

  MonitoringController._(this._repository);

  final AquariumRepository? _repository;
  MonitoringSnapshot _snapshot = const MonitoringSnapshot();
  bool _isRefreshing = false;
  bool _initialized = false;

  MonitoringSnapshot get snapshot => _snapshot;
  bool get isRefreshing => _isRefreshing;
  bool get isInitialized => _initialized;
  bool get remoteConfigured => _repository?.remoteConfigured ?? false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final repository = _repository;
    if (repository == null) {
      _snapshot = const MonitoringSnapshot(
        source: MonitoringSource.notConfigured,
        message: 'Local database is not initialized in this preview.',
      );
      notifyListeners();
      return;
    }

    try {
      final cached = await repository.loadLatestCached();
      final lastSync = await repository.lastSuccessfulSync();
      _snapshot = MonitoringSnapshot(
        readings: cached,
        source: cached.isEmpty
            ? (repository.remoteConfigured
                ? MonitoringSource.offline
                : MonitoringSource.notConfigured)
            : MonitoringSource.cached,
        lastSuccessfulSyncAt: lastSync,
        message: cached.isEmpty
            ? 'No stored telemetry is available yet.'
            : 'Showing locally saved measurements until the next refresh.',
      );
      notifyListeners();
    } catch (error) {
      _snapshot = MonitoringSnapshot(
        source: MonitoringSource.offline,
        message: 'Could not open the local telemetry cache: $error',
      );
      notifyListeners();
    }

    if (repository.remoteConfigured) {
      unawaited(refresh());
    }
  }

  Future<void> refresh() async {
    final repository = _repository;
    if (_isRefreshing || repository == null) return;

    if (!repository.remoteConfigured) {
      try {
        final cached = await repository.loadLatestCached();
        final lastSync = await repository.lastSuccessfulSync();
        _snapshot = MonitoringSnapshot(
          readings: cached,
          source: cached.isEmpty
              ? MonitoringSource.notConfigured
              : MonitoringSource.cached,
          lastCheckedAt: DateTime.now(),
          lastSuccessfulSyncAt: lastSync,
          message: 'Remote API is not configured. Only locally saved records are available.',
        );
      } catch (error) {
        _snapshot = MonitoringSnapshot(
          source: MonitoringSource.offline,
          message: 'Could not read local telemetry storage: $error',
        );
      }
      notifyListeners();
      return;
    }

    _isRefreshing = true;
    notifyListeners();

    try {
      final remoteReadings = await repository.fetchRemoteLatest();
      await repository.cacheReadings(remoteReadings);
      final syncTime = DateTime.now();
      await repository.recordSuccessfulSync(syncTime);
      final cached = await repository.loadLatestCached();
      _snapshot = MonitoringSnapshot(
        readings: cached,
        source: MonitoringSource.remote,
        lastCheckedAt: syncTime,
        lastSuccessfulSyncAt: syncTime,
        message: remoteReadings.isEmpty
            ? 'Backend responded successfully, but it has no telemetry for this device yet.'
            : 'Latest server records were retrieved and saved locally.',
      );
    } catch (error) {
      final cached = await repository.loadLatestCached();
      final lastSync = await repository.lastSuccessfulSync();
      _snapshot = MonitoringSnapshot(
        readings: cached,
        source: cached.isEmpty ? MonitoringSource.offline : MonitoringSource.cached,
        lastCheckedAt: DateTime.now(),
        lastSuccessfulSyncAt: lastSync,
        message: cached.isEmpty
            ? 'Backend refresh failed and no cached readings are available: $error'
            : 'Backend refresh failed. Displaying saved readings instead: $error',
      );
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<List<TelemetryReading>> loadHistory({int limit = 200}) async {
    final repository = _repository;
    if (repository == null) return const [];
    return repository.loadHistory(limit: limit);
  }

  @override
  void dispose() {
    final repository = _repository;
    if (repository != null) {
      unawaited(repository.close());
    }
    super.dispose();
  }
}
