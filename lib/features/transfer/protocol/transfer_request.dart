class TransferRequest {
  final String transferId;
  final String senderDeviceId;
  final String senderDeviceName;
  final String receiverDeviceId;
  final int fileCount;
  final int totalSize;

  const TransferRequest({
    required this.transferId,
    required this.senderDeviceId,
    required this.senderDeviceName,
    required this.receiverDeviceId,
    required this.fileCount,
    required this.totalSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'transferId': transferId,
      'senderDeviceId': senderDeviceId,
      'senderDeviceName': senderDeviceName,
      'receiverDeviceId': receiverDeviceId,
      'fileCount': fileCount,
      'totalSize': totalSize,
    };
  }

  factory TransferRequest.fromJson(
      Map<String, dynamic> json,
      ) {
    return TransferRequest(
      transferId: json['transferId'] as String,
      senderDeviceId:
      json['senderDeviceId'] as String,
      senderDeviceName:
      json['senderDeviceName'] as String,
      receiverDeviceId:
      json['receiverDeviceId'] as String,
      fileCount: json['fileCount'] as int,
      totalSize: json['totalSize'] as int,
    );
  }
}
