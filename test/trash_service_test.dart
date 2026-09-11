import 'dart:io';

import 'package:aircrypt/core/models/trash_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:aircrypt/core/database/database_service.dart';
import 'package:aircrypt/core/database/trash_repository.dart';
import 'package:aircrypt/core/services/trash_service.dart';

import 'fake_file_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('file can move to trash and create a database record', () async {
    final storage = FakeFileStorage();

    final databaseService = DatabaseService(
      databaseName: 'trash_service_test.db',
    );

    final database = await databaseService.database;

    await database.delete('trash');

    final repository = TrashRepository(
      databaseService: databaseService,
    );

    final service = TrashService(
      storage: storage,
      repository: repository,
    );

    final received = await storage.getReceivedDirectory();

    final file = File(
      '${received.path}/notes.pdf',
    );

    await file.writeAsString('test file');

    final item = await service.moveToTrash(
      fileId: 'file-001',
      filePath: file.path,
    );

    expect(await file.exists(), isFalse);

    expect(
      await File(item.trashPath).exists(),
      isTrue,
    );

    final storedItem = await repository.getTrashItem(item.id);

    expect(storedItem, isNotNull);

    expect(
      storedItem!.fileId,
      equals('file-001'),
    );

    await databaseService.close();
    await storage.cleanup();
  });

  test('file can be restored from trash', () async {
    final storage = FakeFileStorage();

    final databaseService = DatabaseService(
      databaseName: 'trash_service_test.db',
    );

    final database = await databaseService.database;

    await database.delete('trash');

    final repository = TrashRepository(
      databaseService: databaseService,
    );

    final service = TrashService(
      storage: storage,
      repository: repository,
    );

    final received = await storage.getReceivedDirectory();

    final file = File(
      '${received.path}/restore.pdf',
    );

    await file.writeAsString('restore me');

    final item = await service.moveToTrash(
      fileId: 'file-002',
      filePath: file.path,
    );

    await service.restore(item);

    expect(
      await File(item.originalPath).exists(),
      isTrue,
    );

    final storedItem = await repository.getTrashItem(item.id);

    expect(storedItem, isNull);

    await databaseService.close();
    await storage.cleanup();
  });

  test('expired files are permanently deleted', () async {
    final storage = FakeFileStorage();

    final databaseService = DatabaseService(
      databaseName: 'trash_service_test.db',
    );

    final database = await databaseService.database;

    await database.delete('trash');

    final repository = TrashRepository(
      databaseService: databaseService,
    );

    final service = TrashService(
      storage: storage,
      repository: repository,
    );

    final trashDirectory = await storage.getTrashDirectory();

    final file = File(
      '${trashDirectory.path}/old.pdf',
    );

    await file.writeAsString('old file');

    await repository.insertTrashItem(
      TrashItem(
        id: 'expired-001',
        fileId: 'file-old',
        originalPath: '${storage.received.path}/old.pdf',
        trashPath: file.path,
        deletedAt: DateTime.now().subtract(
          const Duration(days: 61),
        ),
        permanentDeleteAt: DateTime.now().subtract(
          const Duration(days: 1),
        ),
      ),
    );

    await service.cleanupExpiredItems();

    expect(
      await file.exists(),
      isFalse,
    );

    final storedItem = await repository.getTrashItem(
      'expired-001',
    );

    expect(storedItem, isNull);

    await databaseService.close();
    await storage.cleanup();
  });
}