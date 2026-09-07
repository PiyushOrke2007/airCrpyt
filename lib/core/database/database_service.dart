import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static const String _databaseName = 'aircrypt.db';
  static const int _databaseVersion = 4;

  Database? _database;

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
      _databaseName,
    );

    return openDatabase(
      databasePath,
      version: _databaseVersion,

      onConfigure: (Database database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },

      onCreate: (Database database, int version) async {
        await database.execute('''
    CREATE TABLE transfers (
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
      },
      onUpgrade: (Database database, int oldVersion, int newVersion) async {
        if (oldVersion < 4) {
          await database.execute('''
    CREATE TABLE trash (
      id TEXT PRIMARY KEY,
      file_id TEXT NOT NULL,
      original_path TEXT NOT NULL,
      trash_path TEXT NOT NULL,
      deleted_at TEXT NOT NULL,
      permanent_delete_at TEXT NOT NULL
    )
  ''');
        }
      },
    );
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}