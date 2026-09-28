import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:aircrypt/features/transfer/io/chunk_reader.dart';
import 'package:aircrypt/features/transfer/io/chunk_writer.dart';

void main() {
  test('ChunkReader streams a file in fixed-size chunks', () async {
    final tempDir = await Directory.systemTemp.createTemp();
    final file = File('${tempDir.path}/sample.bin');
    final data = List<int>.generate(150000, (index) => (index * 7) % 251);
    await file.writeAsBytes(data);

    final reader = ChunkReader(file);
    final chunks = await reader.readAllChunks().toList();

    expect(chunks.isNotEmpty, isTrue);
    expect(
      chunks.every((chunk) => chunk.length <= ChunkReader.defaultChunkSize),
      isTrue,
    );
    expect(chunks.expand((chunk) => chunk).length, equals(data.length));

    await tempDir.delete(recursive: true);
  });

  test('ChunkWriter writes and finalizes a received file', () async {
    final tempDir = await Directory.systemTemp.createTemp();
    final temporaryDir = Directory('${tempDir.path}/Temporary');
    final receivedDir = Directory('${tempDir.path}/Received');

    final writer = ChunkWriter(
      temporaryDirectory: temporaryDir,
      receivedDirectory: receivedDir,
    );

    final transferId = 'transfer-1';
    final fileId = 'file-1';
    final originalFileName = 'report.bin';
    final chunkA = List<int>.generate(1024, (index) => index % 256);
    final chunkB = List<int>.generate(512, (index) => (index + 17) % 256);

    await writer.writeChunk(
      transferId: transferId,
      fileId: fileId,
      chunkIndex: 0,
      totalChunks: 2,
      data: chunkA,
      expectedLength: chunkA.length + chunkB.length,
    );
    await writer.writeChunk(
      transferId: transferId,
      fileId: fileId,
      chunkIndex: 1,
      totalChunks: 2,
      data: chunkB,
      expectedLength: chunkA.length + chunkB.length,
    );

    final receivedFile = await writer.finalizeFile(
      transferId: transferId,
      fileId: fileId,
      expectedLength: chunkA.length + chunkB.length,
      fileName: originalFileName,
    );

    expect(receivedFile.existsSync(), isTrue);
    expect(receivedFile.path.endsWith(originalFileName), isTrue);
    expect(
      receivedFile.readAsBytesSync().length,
      equals(chunkA.length + chunkB.length),
    );

    await tempDir.delete(recursive: true);
  });
}
