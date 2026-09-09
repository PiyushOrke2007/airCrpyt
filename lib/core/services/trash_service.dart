import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../database/trash_repository.dart';
import '../database/trash_repository_interface.dart';
import '../models/trash_item.dart';
import 'file_storage.dart';
import 'file_storage_service.dart';

class TrashService {
  final FileStorage _storage;
  final TrashRepositoryInterface _repository;
  final Uuid _uuid;

  TrashService({
    FileStorage? storage,
    TrashRepositoryInterface? repository,
    Uuid? uuid,
  })  : _storage = storage ?? FileStorageService(),
        _repository = repository ?? TrashRepository(),
        _uuid = uuid ?? const Uuid();

  Future<TrashItem> moveToTrash({
    required String fileId,
    required String filePath,
  }) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw FileSystemException(
        'File does not exist.',
        filePath,
      );
    }

    final trashDirectory =
    await _storage.getTrashDirectory();

    final trashFileName =
    await _createUniqueTrashFileName(
      trashDirectory,
      path.basename(file.path),
    );

    final targetPath = path.join(
      trashDirectory.path,
      trashFileName,
    );

    final movedFile = await file.rename(targetPath);

    final deletedAt = DateTime.now();

    final item = TrashItem(
      id: _uuid.v4(),
      fileId: fileId,
      originalPath: filePath,
      trashPath: movedFile.path,
      deletedAt: deletedAt,
      permanentDeleteAt:
      deletedAt.add(
        const Duration(days: 60),
      ),
    );

    await _repository.insertTrashItem(item);

    return item;
  }

  Future<String> _createUniqueTrashFileName(
      Directory directory,
      String originalName,
      ) async {
    final extension = path.extension(originalName);

    final baseName = path.basenameWithoutExtension(
      originalName,
    );

    var candidate = originalName;
    var counter = 1;

    while (
    await File(
      path.join(directory.path, candidate),
    ).exists()) {
      candidate = '$baseName ($counter)$extension';
      counter++;
    }

    return candidate;
  }

  Future<void> restore(TrashItem item) async {
    final file = File(item.trashPath);

    if (!await file.exists()) {
      throw FileSystemException(
        'Trash file does not exist.',
        item.trashPath,
      );
    }

    await _storage.restoreFromTrash(
      file,
      item.originalPath,
    );

    await _repository.deleteTrashItem(item.id);
  }

  Future<void> permanentlyDelete(
      TrashItem item,
      ) async {
    final file = File(item.trashPath);

    await _storage.permanentlyDelete(file);

    await _repository.deleteTrashItem(item.id);
  }

  Future<void> cleanupExpiredItems({
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();

    final expiredItems =
    await _repository.getExpiredItems(
      currentTime,
    );

    for (final item in expiredItems) {
      await permanentlyDelete(item);
    }
  }
}