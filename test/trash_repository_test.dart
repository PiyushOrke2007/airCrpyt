import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:aircrypt/core/database/database_service.dart';
import 'package:aircrypt/core/database/trash_repository.dart';
import 'package:aircrypt/core/models/trash_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('trash item can be inserted and retrieved', () async {
    final databaseService = DatabaseService();
    final database = await databaseService.database;

    await database.delete('trash');

    final repository = TrashRepository(
      databaseService: databaseService,
    );

    final deletedAt = DateTime.now();

    final item = TrashItem(
      id: 'trash-001',
      fileId: 'file-001',
      originalPath: '/Received/notes.pdf',
      trashPath: '/Trash/notes.pdf',
      deletedAt: deletedAt,
      permanentDeleteAt:
      deletedAt.add(const Duration(days: 60)),
    );

    await repository.insertTrashItem(item);

    final result = await repository.getTrashItem(
      'trash-001',
    );

    expect(result, isNotNull);
    expect(result!.fileId, equals('file-001'));
    expect(
      result.originalPath,
      equals('/Received/notes.pdf'),
    );
    expect(
      result.trashPath,
      equals('/Trash/notes.pdf'),
    );

    await databaseService.close();
  });

  test('expired trash items can be found', () async {
    final databaseService = DatabaseService();
    final database = await databaseService.database;

    await database.delete('trash');

    final repository = TrashRepository(
      databaseService: databaseService,
    );

    final oldDate = DateTime.now().subtract(
      const Duration(days: 61),
    );

    final item = TrashItem(
      id: 'trash-expired',
      fileId: 'file-expired',
      originalPath: '/Received/old.pdf',
      trashPath: '/Trash/old.pdf',
      deletedAt: oldDate,
      permanentDeleteAt:
      oldDate.add(const Duration(days: 60)),
    );

    await repository.insertTrashItem(item);

    final expiredItems = await repository.getExpiredItems(
      DateTime.now(),
    );

    expect(expiredItems.length, equals(1));
    expect(
      expiredItems.first.id,
      equals('trash-expired'),
    );

    await databaseService.close();
  });
}