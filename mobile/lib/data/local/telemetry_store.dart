import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/telemetry_reading.dart';

abstract interface class TelemetryStore {
  Future<void> saveReadings(List<TelemetryReading> readings);
  Future<List<TelemetryReading>> getLatestReadings(String deviceId);
  Future<List<TelemetryReading>> getHistory(String deviceId, {int limit = 200});
  Future<DateTime?> getLastSuccessfulSync(String deviceId);
  Future<void> setLastSuccessfulSync(String deviceId, DateTime timestamp);
  Future<void> close();
}

class SqliteTelemetryStore implements TelemetryStore {
  SqliteTelemetryStore._(this._database);

  final Database _database;

  static Future<SqliteTelemetryStore> open() async {
    final databaseDirectory = await getDatabasesPath();
    final databasePath = p.join(databaseDirectory, 'smart_aquarium.db');
    final database = await openDatabase(
      databasePath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE telemetry_samples (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_id TEXT NOT NULL,
            device_id TEXT NOT NULL,
            sensor_code TEXT NOT NULL,
            measurement_value REAL,
            measurement_unit TEXT NOT NULL,
            is_valid INTEGER NOT NULL CHECK (is_valid IN (0, 1)),
            measured_at TEXT NOT NULL,
            received_at TEXT NOT NULL,
            time_quality TEXT NOT NULL,
            sequence_number INTEGER NOT NULL,
            UNIQUE (event_id, sensor_code)
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_local_telemetry_device_sensor_time
          ON telemetry_samples (device_id, sensor_code, measured_at DESC)
        ''');
        await db.execute('''
          CREATE TABLE sync_metadata (
            metadata_key TEXT PRIMARY KEY,
            metadata_value TEXT NOT NULL
          )
        ''');
      },
    );
    return SqliteTelemetryStore._(database);
  }

  @override
  Future<void> saveReadings(List<TelemetryReading> readings) async {
    if (readings.isEmpty) return;
    final batch = _database.batch();
    for (final reading in readings) {
      batch.insert(
        'telemetry_samples',
        reading.toDatabaseMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<TelemetryReading>> getLatestReadings(String deviceId) async {
    final rows = await _database.query(
      'telemetry_samples',
      where: 'device_id = ?',
      whereArgs: [deviceId],
      orderBy: 'measured_at DESC, sequence_number DESC',
      limit: 500,
    );

    final latestBySensor = <String, TelemetryReading>{};
    for (final row in rows) {
      final reading = TelemetryReading.fromDatabaseMap(row);
      latestBySensor.putIfAbsent(reading.sensorCode, () => reading);
    }
    return latestBySensor.values.toList(growable: false);
  }

  @override
  Future<List<TelemetryReading>> getHistory(
    String deviceId, {
    int limit = 200,
  }) async {
    final safeLimit = limit.clamp(1, 1000).toInt();
    final rows = await _database.query(
      'telemetry_samples',
      where: 'device_id = ?',
      whereArgs: [deviceId],
      orderBy: 'measured_at DESC, sequence_number DESC',
      limit: safeLimit,
    );
    return rows.map(TelemetryReading.fromDatabaseMap).toList(growable: false);
  }

  String _syncKey(String deviceId) => 'last_successful_sync:$deviceId';

  @override
  Future<DateTime?> getLastSuccessfulSync(String deviceId) async {
    final rows = await _database.query(
      'sync_metadata',
      columns: ['metadata_value'],
      where: 'metadata_key = ?',
      whereArgs: [_syncKey(deviceId)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['metadata_value'] as String)?.toLocal();
  }

  @override
  Future<void> setLastSuccessfulSync(String deviceId, DateTime timestamp) async {
    await _database.insert(
      'sync_metadata',
      {
        'metadata_key': _syncKey(deviceId),
        'metadata_value': timestamp.toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> close() => _database.close();
}
