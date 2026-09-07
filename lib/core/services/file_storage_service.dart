import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'file_storage.dart';

class FileStorageService implements FileStorage {
  static const String _rootDirectoryName = 'P2PShare';

  static const String receivedDirectoryName = 'Received';
  static const String sentDirectoryName = 'Sent';
  static const String temporaryDirectoryName = 'Temporary';
  static const String trashDirectoryName = 'Trash';

  @override
  Future<Directory> getRootDirectory() async {
    final baseDirectory =
    await getApplicationDocumentsDirectory();

    final rootDirectory = Directory(
      path.join(
        baseDirectory.path,
        _rootDirectoryName,
      ),
    );

    await rootDirectory.create(recursive: true);

    return rootDirectory;
  }

  @override
  Future<Directory> getReceivedDirectory() {
    return _getSubdirectory(receivedDirectoryName);
  }

  @override
  Future<Directory> getSentDirectory() {
    return _getSubdirectory(sentDirectoryName);
  }

  @override
  Future<Directory> getTemporaryDirectory() {
    return _getSubdirectory(temporaryDirectoryName);
  }

  @override
  Future<Directory> getTrashDirectory() {
    return _getSubdirectory(trashDirectoryName);
  }

  Future<Directory> _getSubdirectory(
      String name,
      ) async {
    final rootDirectory = await getRootDirectory();

    final directory = Directory(
      path.join(
        rootDirectory.path,
        name,
      ),
    );

    await directory.create(recursive: true);

    return directory;
  }

  @override
  Future<File> moveToTrash(File file) async {
    final trashDirectory =
    await getTrashDirectory();

    final destination = path.join(
      trashDirectory.path,
      path.basename(file.path),
    );

    return file.rename(destination);
  }

  @override
  Future<File> restoreFromTrash(
      File file,
      String originalPath,
      ) async {
    final destinationParent =
    Directory(path.dirname(originalPath));

    await destinationParent.create(
      recursive: true,
    );

    return file.rename(originalPath);
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
    final directory =
    await getTemporaryDirectory();

    if (await directory.exists()) {
      await directory.delete(
        recursive: true,
      );
    }
  }
}