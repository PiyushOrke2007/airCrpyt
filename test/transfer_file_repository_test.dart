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

  test('multiple files can belong to one transfer', () async {
    final databaseService = DatabaseService();

    final database = await databaseService.database;

    await database.delete('transfer_files');
    await database.delete('transfers');

    final repository = TransferRepository(
      databaseService: databaseService,
    );

    final transfer = Transfer(
      id: 'transfer-001',
      type: TransferType.send,
      status: TransferStatus.completed,
      peerDeviceId: 'device-001',
      peerDeviceName: 'Rahul Phone',
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      totalSize: 3072,
    );

    await repository.insertTransfer(transfer);

    final file1 = TransferFile(
      id: 'file-001',
      transferId: transfer.id,
      fileName: 'notes.pdf',
      fileSize: 1024,
      status: TransferFileStatus.completed,
    );

    final file2 = TransferFile(
      id: 'file-002',
      transferId: transfer.id,
      fileName: 'assignment.docx',
      fileSize: 2048,
      status: TransferFileStatus.completed,
    );

    await repository.insertTransferFile(file1);
    await repository.insertTransferFile(file2);

    final files = await repository.getTransferFiles(
      transfer.id,
    );

    expect(files.length, equals(2));
    expect(files[0].transferId, equals(transfer.id));
    expect(files[1].transferId, equals(transfer.id));

    await databaseService.close();
  });
}