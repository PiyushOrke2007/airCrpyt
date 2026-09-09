import 'package:aircrypt/core/database/trash_repository_interface.dart';
import 'package:sqflite/sqflite.dart';

import '../models/trash_item.dart';
import 'database_service.dart';

class TrashRepository implements TrashRepositoryInterface {
  final DatabaseService _databaseService;

  TrashRepository({
    DatabaseService? databaseService,
  }) : _databaseService = databaseService ?? DatabaseService();

  Future<void> insertTrashItem(TrashItem item) async {
    final database = await _databaseService.database;

    await database.insert(
      'trash',
      {
        'id': item.id,
        'file_id': item.fileId,
        'original_path': item.originalPath,
        'trash_path': item.trashPath,
        'deleted_at': item.deletedAt.toIso8601String(),
        'permanent_delete_at':
        item.permanentDeleteAt.toIso8601String(),
      },
    );
  }

  Future<TrashItem?> getTrashItem(String id) async {
    final database = await _databaseService.database;

    final results = await database.query(
      'trash',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return _fromMap(results.first);
  }

  Future<List<TrashItem>> getAllTrashItems() async {
    final database = await _databaseService.database;

    final results = await database.query(
      'trash',
      orderBy: 'deleted_at DESC',
    );

    return results.map(_fromMap).toList();
  }

  Future<void> deleteTrashItem(String id) async {
    final database = await _databaseService.database;

    await database.delete(
      'trash',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TrashItem>> getExpiredItems(
      DateTime now,
      ) async {
    final database = await _databaseService.database;

    final results = await database.query(
      'trash',
      where: 'permanent_delete_at <= ?',
      whereArgs: [now.toIso8601String()],
      orderBy: 'permanent_delete_at ASC',
    );

    return results.map(_fromMap).toList();
  }

  TrashItem _fromMap(Map<String, Object?> map) {
    return TrashItem(
      id: map['id']! as String,
      fileId: map['file_id']! as String,
      originalPath: map['original_path']! as String,
      trashPath: map['trash_path']! as String,
      deletedAt: DateTime.parse(
        map['deleted_at']! as String,
      ),
      permanentDeleteAt: DateTime.parse(
        map['permanent_delete_at']! as String,
      ),
    );
  }
}