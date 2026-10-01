import 'dart:io';
import 'dart:typed_data';

class ChunkReader {
  static const int defaultChunkSize = 64 * 1024;

  final File file;
  final int chunkSize;

  const ChunkReader(this.file, {this.chunkSize = defaultChunkSize});

  Stream<List<int>> readAllChunks() async* {
    if (!await file.exists()) {
      throw FileSystemException('File not found', file.path);
    }

    final randomAccessFile = await file.open(mode: FileMode.read);

    try {
      while (true) {
        final chunk = await randomAccessFile.read(chunkSize);

        if (chunk.isEmpty) {
          break;
        }

        yield Uint8List.fromList(chunk);
      }
    } finally {
      await randomAccessFile.close();
    }
  }
}
