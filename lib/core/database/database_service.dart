import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static const String _defaultDatabaseName =
      'aircrypt.db';

  final String databaseName;
  static const int _databaseVersion = 4;

  Database? _database;

  DatabaseService({
    this.databaseName = _defaultDatabaseName,
  });

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initializeDatabase();

    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    final databaseDirectory = await getDatabasesPath();

    final databasePath = path.join(
      databaseDirectory,
      databaseName,
    );

    return openDatabase(
      databasePath,
      version: _databaseVersion,

      onConfigure: (Database database) async {
        await database.execute(
          'PRAGMA foreign_keys = ON',
        );
      },

      onCreate: (Database database, int version) async {
        await _createAllTables(database);
      },

      onUpgrade: (
          Database database,
          int oldVersion,
          int newVersion,
          ) async {
        if (oldVersion < 2) {
          await _createTransfersTable(database);
        }

        if (oldVersion < 3) {
          await _createTransferFilesTable(database);
        }

        if (oldVersion < 4) {
          await _createTrashTable(database);
        }
      },
    );
  }

  Future<void> _createAllTables(
      Database database,
      ) async {
    await _createTransfersTable(database);
    await _createTransferFilesTable(database);
    await _createTrashTable(database);
  }

  Future<void> _createTransfersTable(
      Database database,
      ) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS transfers (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        peer_device_id TEXT NOT NULL,
        peer_device_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        total_size INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createTransferFilesTable(
      Database database,
      ) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS transfer_files (
        id TEXT PRIMARY KEY,
        transfer_id TEXT NOT NULL,
        file_name TEXT NOT NULL,
        relative_path TEXT,
        file_size INTEGER NOT NULL,
        status TEXT NOT NULL,
        source_path TEXT,
        saved_path TEXT,
        FOREIGN KEY (transfer_id)
          REFERENCES transfers(id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createTrashTable(
      Database database,
      ) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS trash (
        id TEXT PRIMARY KEY,
        file_id TEXT NOT NULL,
        original_path TEXT NOT NULL,
        trash_path TEXT NOT NULL,
        deleted_at TEXT NOT NULL,
        permanent_delete_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}