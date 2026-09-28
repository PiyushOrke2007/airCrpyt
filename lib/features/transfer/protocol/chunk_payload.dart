import 'dart:convert';
import 'dart:typed_data';

import 'chunk_metadata.dart';

class ChunkPayload {
  final ChunkMetadata metadata;
  final List<int> data;

  const ChunkPayload({required this.metadata, required this.data});

  Uint8List encode() {
    final metadataJson = jsonEncode(metadata.toJson());
    final metadataBytes = utf8.encode(metadataJson);
    final headerLength = metadataBytes.length;

    final buffer = ByteData(4 + headerLength + data.length);
    buffer.setUint32(0, headerLength, Endian.big);

    final result = buffer.buffer.asUint8List();
    result.setRange(4, 4 + headerLength, metadataBytes);
    result.setRange(4 + headerLength, result.length, data);

    return result;
  }

  factory ChunkPayload.decode(List<int> payload) {
    if (payload.length < 4) {
      throw const FormatException(
        'Chunk payload too short to contain metadata length header',
      );
    }

    final byteData = ByteData.sublistView(Uint8List.fromList(payload), 0, 4);
    final metadataLength = byteData.getUint32(0, Endian.big);

    if (payload.length < 4 + metadataLength) {
      throw FormatException(
        'Chunk payload length ${payload.length} is less than required header size ${4 + metadataLength}',
      );
    }

    final metadataBytes = payload.sublist(4, 4 + metadataLength);
    final metadataJson = utf8.decode(metadataBytes);
    final metadataMap = jsonDecode(metadataJson) as Map<String, dynamic>;
    final metadata = ChunkMetadata.fromJson(metadataMap);

    final chunkData = payload.sublist(4 + metadataLength);

    return ChunkPayload(metadata: metadata, data: chunkData);
  }
}
