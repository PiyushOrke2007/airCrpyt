import 'dart:io';

import 'package:path/path.dart' as path;

class ChunkWriter {
  final Directory temporaryDirectory;
  final Directory receivedDirectory;

  ChunkWriter({
    required this.temporaryDirectory,
    required this.receivedDirectory,
  });

  Future<void> writeChunk({
    required String transferId,
    required String fileId,
    required int chunkIndex,
    required int totalChunks,
    required List<int> data,
    required int expectedLength,
  }) async {
    final transferDirectory = Directory(
      path.join(temporaryDirectory.path, transferId, fileId),
    );

    await transferDirectory.create(recursive: true);

    final chunkFile = File(
      path.join(
        transferDirectory.path,
        'chunk_${chunkIndex.toString().padLeft(6, '0')}.bin',
      ),
    );

    await chunkFile.writeAsBytes(data);

    final totalBytesWritten = await _sumChunkSizes(transferDirectory);
    if (totalBytesWritten > expectedLength) {
      throw StateError(
        'Chunk payload exceeds expected transfer length for $fileId',
      );
    }

    if (totalChunks > 0 && totalBytesWritten > 0 && chunkIndex >= totalChunks) {
      throw StateError(
        'Chunk index $chunkIndex exceeds total chunk count $totalChunks',
      );
    }
  }

  Future<File> finalizeFile({
    required String transferId,
    required String fileId,
    required int expectedLength,
    required String fileName,
  }) async {
    final transferDirectory = Directory(
      path.join(temporaryDirectory.path, transferId, fileId),
    );

    if (!await transferDirectory.exists()) {
      throw FileSystemException(
        'Transfer chunk directory not found',
        transferDirectory.path,
      );
    }

    final chunkFiles =
        (await transferDirectory.list().toList()).whereType<File>().toList()
          ..sort((a, b) {
            final aIndex = _extractChunkIndex(a.path);
            final bIndex = _extractChunkIndex(b.path);
            return aIndex.compareTo(bIndex);
          });

    await receivedDirectory.create(recursive: true);

    final destination = File(
      path.join(receivedDirectory.path, path.basename(fileName)),
    );

    final output = await destination.create(recursive: true);
    final sink = output.openWrite();

    try {
      for (final chunkFile in chunkFiles) {
        final bytes = await chunkFile.readAsBytes();
        sink.add(bytes);
      }
    } finally {
      await sink.close();
    }

    final actualSize = await output.length();
    if (actualSize != expectedLength) {
      await output.delete();
      throw StateError(
        'Received file size $actualSize does not match expected length $expectedLength',
      );
    }

    if (await transferDirectory.exists()) {
      try {
        await transferDirectory.delete(recursive: true);
      } catch (_) {}
    }
    return output;
  }

  Future<int> _sumChunkSizes(Directory directory) async {
    int total = 0;

    if (!await directory.exists()) return 0;

    try {
      final entries = await directory.list().toList();
      for (final entry in entries) {
        if (entry is File) {
          try {
            if (await entry.exists()) {
              total += await entry.length();
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    return total;
  }

  int _extractChunkIndex(String filePath) {
    final fileName = path.basename(filePath);
    final match = RegExp(r'chunk_(\d+)\.bin').firstMatch(fileName);
    if (match == null) {
      return 0;
    }

    return int.parse(match.group(1)!);
  }
}
