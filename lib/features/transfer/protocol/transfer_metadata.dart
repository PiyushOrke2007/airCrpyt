import 'file_metadata.dart';

class TransferMetadata {
  final String transferId;
  final int totalFiles;
  final int totalSize;
  final List<FileMetadata> files;

  const TransferMetadata({
    required this.transferId,
    required this.totalFiles,
    required this.totalSize,
    required this.files,
  });

  Map<String, dynamic> toJson() {
    return {
      'transferId': transferId,
      'totalFiles': totalFiles,
      'totalSize': totalSize,
      'files': files
          .map((file) => file.toJson())
          .toList(),
    };
  }

  factory TransferMetadata.fromJson(
      Map<String, dynamic> json,
      ) {
    final filesJson =
    json['files'] as List<dynamic>;

    return TransferMetadata(
      transferId: json['transferId'] as String,
      totalFiles: json['totalFiles'] as int,
      totalSize: json['totalSize'] as int,
      files: filesJson
          .map(
            (file) => FileMetadata.fromJson(
          file as Map<String, dynamic>,
        ),
      )
          .toList(),
    );
  }
}
