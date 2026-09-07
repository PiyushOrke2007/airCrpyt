import 'dart:io';

abstract class FileStorage {
  Future<Directory> getRootDirectory();

  Future<Directory> getReceivedDirectory();

  Future<Directory> getSentDirectory();

  Future<Directory> getTemporaryDirectory();

  Future<Directory> getTrashDirectory();

  Future<File> moveToTrash(
      File file,
      );

  Future<File> restoreFromTrash(
      File file,
      String originalPath,
      );

  Future<void> permanentlyDelete(
      File file,
      );

  Future<void> deleteTemporaryDirectory();
}