import 'dart:io';

import 'package:aircrypt/core/services/file_storage.dart';

class FakeFileStorage implements FileStorage {
  final Directory root =
  Directory('test_storage');

  final Directory received =
  Directory('test_storage/Received');

  final Directory sent =
  Directory('test_storage/Sent');

  final Directory temporary =
  Directory('test_storage/Temporary');

  final Directory trash =
  Directory('test_storage/Trash');

  @override
  Future<Directory> getRootDirectory() async {
    await root.create(recursive: true);
    return root;
  }

  @override
  Future<Directory> getReceivedDirectory() async {
    await received.create(recursive: true);
    return received;
  }

  @override
  Future<Directory> getSentDirectory() async {
    await sent.create(recursive: true);
    return sent;
  }

  @override
  Future<Directory> getTemporaryDirectory() async {
    await temporary.create(recursive: true);
    return temporary;
  }

  @override
  Future<Directory> getTrashDirectory() async {
    await trash.create(recursive: true);
    return trash;
  }

  @override
  Future<File> moveToTrash(
      File file,
      ) async {
    final destination = File(
      '${trash.path}/${file.uri.pathSegments.last}',
    );

    return file.rename(destination.path);
  }

  @override
  Future<File> restoreFromTrash(
      File file,
      String originalPath,
      ) async {
    final destination = File(originalPath);

    await destination.parent.create(
      recursive: true,
    );

    return file.rename(destination.path);
  }

  @override
  Future<void> permanentlyDelete(
      File file,
      ) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> deleteTemporaryDirectory() async {
    if (await temporary.exists()) {
      await temporary.delete(
        recursive: true,
      );
    }
  }
}