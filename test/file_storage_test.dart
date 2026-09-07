import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:aircrypt/core/services/file_storage.dart';

import 'fake_file_storage.dart';

void main() {
  group('FileStorage', () {
    late FileStorage storage;

    setUp(() {
      storage = FakeFileStorage();
    });

    test('creates root directory', () async {
      final directory = await storage.getRootDirectory();

      expect(
        await directory.exists(),
        isTrue,
      );
    });

    test('creates all required directories', () async {
      final received =
      await storage.getReceivedDirectory();

      final sent =
      await storage.getSentDirectory();

      final temporary =
      await storage.getTemporaryDirectory();

      final trash =
      await storage.getTrashDirectory();

      expect(await received.exists(), isTrue);
      expect(await sent.exists(), isTrue);
      expect(await temporary.exists(), isTrue);
      expect(await trash.exists(), isTrue);
    });

    test('file can be moved to trash', () async {
      final received =
      await storage.getReceivedDirectory();

      final trash =
      await storage.getTrashDirectory();

      final file = File(
        '${received.path}/notes.pdf',
      );

      await file.writeAsString('test file');

      final movedFile =
      await storage.moveToTrash(file);

      expect(
        await file.exists(),
        isFalse,
      );

      expect(
        await movedFile.exists(),
        isTrue,
      );

      expect(
        movedFile.path,
        equals(
          '${trash.path}/notes.pdf',
        ),
      );

      await movedFile.delete();
    });

    test('file can be restored from trash', () async {
      final received =
      await storage.getReceivedDirectory();

      final trash =
      await storage.getTrashDirectory();

      final trashFile = File(
        '${trash.path}/notes.pdf',
      );

      await trashFile.writeAsString('test file');

      final originalPath =
          '${received.path}/notes.pdf';

      final restoredFile =
      await storage.restoreFromTrash(
        trashFile,
        originalPath,
      );

      expect(
        await restoredFile.exists(),
        isTrue,
      );

      expect(
        restoredFile.path,
        equals(originalPath),
      );

      await restoredFile.delete();
    });

    test('file can be permanently deleted', () async {
      final trash =
      await storage.getTrashDirectory();

      final file = File(
        '${trash.path}/delete-me.pdf',
      );

      await file.writeAsString('delete me');

      expect(
        await file.exists(),
        isTrue,
      );

      await storage.permanentlyDelete(file);

      expect(
        await file.exists(),
        isFalse,
      );
    });
  });
}