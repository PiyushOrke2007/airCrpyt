import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:aircrypt/core/database/database_service.dart';
import 'package:aircrypt/core/database/transfer_repository.dart';
import 'package:aircrypt/core/models/transfer.dart';
import 'package:aircrypt/core/models/transfer_file.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('transfer can be inserted and retrieved', () async {
    final databaseService = DatabaseService();

    final database = await databaseService.database;

    await database.delete('transfers');

    final repository = TransferRepository(databaseService: databaseService);

    final createdAt = DateTime.now();

    final transfer = Transfer(
      id: 'test-transfer-001',
      type: TransferType.send,
      status: TransferStatus.completed,
      peerDeviceId: 'device-001',
      peerDeviceName: 'Rahul Phone',
      createdAt: createdAt,
      completedAt: createdAt,
      totalSize: 1024,
    );

    await repository.insertTransfer(transfer);

    final result = await repository.getTransfer('test-transfer-001');

    expect(result, isNotNull);
    expect(result!.id, equals('test-transfer-001'));
    expect(result.type, equals(TransferType.send));
    expect(result.status, equals(TransferStatus.completed));
    expect(result.peerDeviceName, equals('Rahul Phone'));
    expect(result.totalSize, equals(1024));

    await databaseService.close();
  });

  test('repository updates transfer and file status', () async {
    final databaseService = DatabaseService();
    final database = await databaseService.database;
    await database.delete('transfers');
    await database.delete('transfer_files');

    final repository = TransferRepository(databaseService: databaseService);

    final createdAt = DateTime.now();
    final transfer = Transfer(
      id: 'test-transfer-002',
      type: TransferType.receive,
      status: TransferStatus.waitingForAcceptance,
      peerDeviceId: 'device-002',
      peerDeviceName: 'Laptop',
      createdAt: createdAt,
      totalSize: 4096,
    );

    await repository.insertTransfer(transfer);
    await repository.insertTransferFile(
      TransferFile(
        id: 'test-file-002',
        transferId: transfer.id,
        fileName: 'report.pdf',
        fileSize: 4096,
        status: TransferFileStatus.pending,
      ),
    );

    await repository.updateTransferStatus(
      transfer.id,
      TransferStatus.transferring,
    );
    await repository.updateTransferFileStatus(
      'test-file-002',
      TransferFileStatus.transferring,
    );

    final updatedTransfer = await repository.getTransfer(transfer.id);
    final updatedFiles = await repository.getTransferFiles(transfer.id);

    expect(updatedTransfer!.status, equals(TransferStatus.transferring));
    expect(updatedFiles.single.status, equals(TransferFileStatus.transferring));

    await databaseService.close();
  });
}
