import 'dart:convert';
import 'dart:typed_data';

class SecureChunk {
  final String transferId;
  final String fileId;
  final int chunkIndex;
  final int totalChunks;
  final int plaintextLength;
  final Uint8List ciphertext;
  final Uint8List nonce;
  final Uint8List gcmTag;
  final Uint8List sha256;

  const SecureChunk({
    required this.transferId,
    required this.fileId,
    required this.chunkIndex,
    required this.totalChunks,
    required this.plaintextLength,
    required this.ciphertext,
    required this.nonce,
    required this.gcmTag,
    required this.sha256,
  });

  Map<String, dynamic> toJson() => {
    'transferId': transferId,
    'fileId': fileId,
    'chunkIndex': chunkIndex,
    'totalChunks': totalChunks,
    'plaintextLength': plaintextLength,
    'ciphertext': base64Encode(ciphertext),
    'nonce': base64Encode(nonce),
    'gcmTag': base64Encode(gcmTag),
    'sha256': base64Encode(sha256),
  };

  factory SecureChunk.fromJson(Map<String, dynamic> json) {
    return SecureChunk(
      transferId: json['transferId'] as String,
      fileId: json['fileId'] as String,
      chunkIndex: json['chunkIndex'] as int,
      totalChunks: json['totalChunks'] as int,
      plaintextLength: json['plaintextLength'] as int? ?? 0,
      ciphertext: _decode64(json['ciphertext'] as String),
      nonce: _decode64(json['nonce'] as String),
      gcmTag: _decode64(json['gcmTag'] as String),
      sha256: _decode64(json['sha256'] as String),
    );
  }

  static Uint8List _decode64(String value) =>
      Uint8List.fromList(base64Decode(value));
}
