class FileMetadata {
  final String fileId;
  final String fileName;
  final String? relativePath;
  final int fileSize;
  final int totalChunks;

  const FileMetadata({
    required this.fileId,
    required this.fileName,
    this.relativePath,
    required this.fileSize,
    required this.totalChunks,
  });

  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'fileName': fileName,
      'relativePath': relativePath,
      'fileSize': fileSize,
      'totalChunks': totalChunks,
    };
  }

  factory FileMetadata.fromJson(
      Map<String, dynamic> json,
      ) {
    return FileMetadata(
      fileId: json['fileId'] as String,
      fileName: json['fileName'] as String,
      relativePath:
      json['relativePath'] as String?,
      fileSize: json['fileSize'] as int,
      totalChunks: json['totalChunks'] as int,
    );
  }
}
