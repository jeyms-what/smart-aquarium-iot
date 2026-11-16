import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

abstract interface class FishCareProfileStore {
  Future<String?> loadSelectedSpeciesId();
  Future<void> saveSelectedSpeciesId(String speciesId);
  Future<void> close();
}

/// In-memory implementation used by widget previews and tests.
class InMemoryFishCareProfileStore implements FishCareProfileStore {
  String? selectedSpeciesId;

  @override
  Future<String?> loadSelectedSpeciesId() async => selectedSpeciesId;

  @override
  Future<void> saveSelectedSpeciesId(String speciesId) async {
    selectedSpeciesId = speciesId;
  }

  @override
  Future<void> close() async {}
}

/// Small independent SQLite store so fish-care profile persistence does not
/// alter or migrate the existing telemetry database.
class SqliteFishCareProfileStore implements FishCareProfileStore {
  SqliteFishCareProfileStore._(this._database);

  final Database _database;

  static Future<SqliteFishCareProfileStore> open() async {
    final directory = await getDatabasesPath();
    final database = await openDatabase(
      p.join(directory, 'aquacare_fish_care.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE selected_fish_profile (
            profile_key TEXT PRIMARY KEY,
            species_id TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
    return SqliteFishCareProfileStore._(database);
  }

  @override
  Future<String?> loadSelectedSpeciesId() async {
    final rows = await _database.query(
      'selected_fish_profile',
      columns: ['species_id'],
      where: 'profile_key = ?',
      whereArgs: ['primary'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['species_id'] as String;
  }

  @override
  Future<void> saveSelectedSpeciesId(String speciesId) async {
    await _database.insert(
      'selected_fish_profile',
      {
        'profile_key': 'primary',
        'species_id': speciesId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> close() => _database.close();
}
