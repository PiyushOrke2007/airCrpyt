enum TransferFileStatus {
  pending,
  transferring,
  completed,
  failed,
  cancelled,
}

class TransferFile {
  final String id;
  final String transferId;
  final String fileName;
  final String? relativePath;
  final int fileSize;
  final TransferFileStatus status;
  final String? sourcePath;
  final String? savedPath;

  const TransferFile({
    required this.id,
    required this.transferId,
    required this.fileName,
    this.relativePath,
    required this.fileSize,
    required this.status,
    this.sourcePath,
    this.savedPath,
  });
}