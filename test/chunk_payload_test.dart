import 'package:flutter_test/flutter_test.dart';

import 'package:aircrypt/features/transfer/protocol/chunk_metadata.dart';
import 'package:aircrypt/features/transfer/protocol/chunk_payload.dart';

void main() {
  test('ChunkPayload encodes and decodes accurately', () {
    const metadata = ChunkMetadata(
      transferId: 'trans_123',
      fileId: 'file_456',
      chunkIndex: 2,
      totalChunks: 5,
      payloadLength: 10,
    );
    final rawData = List<int>.generate(10, (i) => i * 10);

    final payload = ChunkPayload(metadata: metadata, data: rawData);
    final encoded = payload.encode();

    final decoded = ChunkPayload.decode(encoded);

    expect(decoded.metadata.transferId, equals('trans_123'));
    expect(decoded.metadata.fileId, equals('file_456'));
    expect(decoded.metadata.chunkIndex, equals(2));
    expect(decoded.metadata.totalChunks, equals(5));
    expect(decoded.metadata.payloadLength, equals(10));
    expect(decoded.data, equals(rawData));
  });

  test('ChunkPayload decode throws on truncated header', () {
    expect(() => ChunkPayload.decode([0, 0]), throwsA(isA<FormatException>()));
  });
}
