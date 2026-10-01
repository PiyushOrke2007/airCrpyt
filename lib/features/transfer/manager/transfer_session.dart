enum TransferSessionStatus {
  waiting,
  connecting,
  sending,
  completed,
  failed,
  rejected,
}

class TransferSession {
  final String transferId;
  final String deviceId;
  final String deviceName;
  final int fileCount;
  final int totalBytes;
  final DateTime createdAt;

  TransferSessionStatus status;
  double progress;
  String? error;

  TransferSession({
    required this.transferId,
    required this.deviceId,
    required this.deviceName,
    required this.fileCount,
    required this.totalBytes,
    this.status = TransferSessionStatus.waiting,
    this.progress = 0.0,
    this.error,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progressPercent => progress.clamp(0.0, 1.0) * 100;
}
