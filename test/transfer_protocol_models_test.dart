import 'package:flutter_test/flutter_test.dart';

import 'package:aircrypt/features/transfer/protocol/file_metadata.dart';
import 'package:aircrypt/features/transfer/protocol/json_payload.dart';
import 'package:aircrypt/features/transfer/protocol/transfer_metadata.dart';
import 'package:aircrypt/features/transfer/protocol/transfer_request.dart';

void main() {
  test('TransferRequest survives JSON conversion', () {
    const original = TransferRequest(
      transferId: 'T001',
      senderDeviceId: 'sender-001',
      senderDeviceName: 'Piyush Laptop',
      receiverDeviceId: 'receiver-001',
      fileCount: 2,
      totalSize: 5000,
    );

    final encoded = JsonPayload.encode(
      original.toJson(),
    );

    final decodedJson = JsonPayload.decode(
      encoded,
    );

    final decoded =
    TransferRequest.fromJson(
      decodedJson,
    );

    expect(
      decoded.transferId,
      equals(original.transferId),
    );

    expect(
      decoded.senderDeviceName,
      equals(original.senderDeviceName),
    );

    expect(
      decoded.fileCount,
      equals(original.fileCount),
    );

    expect(
      decoded.totalSize,
      equals(original.totalSize),
    );
  });

  test('TransferMetadata supports multiple files', () {
    const metadata = TransferMetadata(
      transferId: 'T002',
      totalFiles: 2,
      totalSize: 3000,
      files: [
        FileMetadata(
          fileId: 'F001',
          fileName: 'notes.pdf',
          fileSize: 1000,
          totalChunks: 2,
        ),
        FileMetadata(
          fileId: 'F002',
          fileName: 'Unit1/diagram.png',
          relativePath: 'Unit1/diagram.png',
          fileSize: 2000,
          totalChunks: 3,
        ),
      ],
    );

    final encoded = JsonPayload.encode(
      metadata.toJson(),
    );

    final decodedJson =
    JsonPayload.decode(encoded);

    final decoded =
    TransferMetadata.fromJson(
      decodedJson,
    );

    expect(decoded.files.length, equals(2));

    expect(
      decoded.files[0].fileName,
      equals('notes.pdf'),
    );

    expect(
      decoded.files[1].relativePath,
      equals('Unit1/diagram.png'),
    );
  });
}
