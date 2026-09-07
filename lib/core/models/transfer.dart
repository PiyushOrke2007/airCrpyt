enum TransferType {
  send,
  receive,
}

enum TransferStatus {
  requesting,
  waitingForAcceptance,
  verifying,
  checkingStorage,
  accepted,
  transferring,
  paused,
  resuming,
  verifyingFile,
  completed,
  rejected,
  cancelled,
  failed,
}

class Transfer {
  final String id;
  final TransferType type;
  final TransferStatus status;
  final String peerDeviceId;
  final String peerDeviceName;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int totalSize;

  const Transfer({
    required this.id,
    required this.type,
    required this.status,
    required this.peerDeviceId,
    required this.peerDeviceName,
    required this.createdAt,
    this.completedAt,
    required this.totalSize,
  });
}