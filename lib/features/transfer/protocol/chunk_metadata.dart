class ChunkMetadata {
  final String transferId;
  final String fileId;
  final int chunkIndex;
  final int totalChunks;
  final int payloadLength;

  const ChunkMetadata({
    required this.transferId,
    required this.fileId,
    required this.chunkIndex,
    required this.totalChunks,
    required this.payloadLength,
  });

  Map<String, dynamic> toJson() {
    return {
      'transferId': transferId,
      'fileId': fileId,
      'chunkIndex': chunkIndex,
      'totalChunks': totalChunks,
      'payloadLength': payloadLength,
    };
  }

  factory ChunkMetadata.fromJson(
      Map<String, dynamic> json,
      ) {
    return ChunkMetadata(
      transferId: json['transferId'] as String,
      fileId: json['fileId'] as String,
      chunkIndex: json['chunkIndex'] as int,
      totalChunks: json['totalChunks'] as int,
      payloadLength:
      json['payloadLength'] as int,
    );
  }
}
