import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:aircrypt/core/database/database_service.dart';
import 'package:aircrypt/core/database/transfer_repository.dart';
import 'package:aircrypt/core/models/transfer.dart';
import 'package:aircrypt/features/transfer/manager/transfer_manager.dart';
import 'package:aircrypt/features/transfer/manager/transfer_receiver.dart';
import 'package:aircrypt/features/transfer/manager/transfer_sender.dart';
import 'package:aircrypt/features/transfer/protocol/json_payload.dart';
import 'package:aircrypt/features/transfer/protocol/message_type.dart';
import 'package:aircrypt/features/transfer/protocol/protocol_message.dart';
import 'package:aircrypt/features/transfer/protocol/transfer_request.dart';

void main() {
  late Directory tempDir;
  late Directory receivedDir;
  late Directory testFilesDir;
  late DatabaseService senderDbService;
  late DatabaseService receiverDbService;
  late TransferRepository senderRepository;
  late TransferRepository receiverRepository;
  late TransferManager senderManager;
  late TransferManager receiverManager;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final systemTemp = Directory.systemTemp.createTempSync('aircrypt_e2e_');
    tempDir = Directory(path.join(systemTemp.path, 'temporary'))..createSync();
    receivedDir = Directory(path.join(systemTemp.path, 'received'))
      ..createSync();
    testFilesDir = Directory(path.join(systemTemp.path, 'test_files'))
      ..createSync();

    senderDbService = DatabaseService(
      databaseName: 'sender_test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    receiverDbService = DatabaseService(
      databaseName: 'receiver_test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    senderRepository = TransferRepository(databaseService: senderDbService);
    receiverRepository = TransferRepository(databaseService: receiverDbService);

    senderManager = TransferManager();
    receiverManager = TransferManager();
  });

  tearDown(() async {
    senderManager.dispose();
    receiverManager.dispose();
    await senderDbService.close();
    await receiverDbService.close();
    try {
      tempDir.parent.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('End-to-end file transfer (single and multi-file)', () async {
    final file1 = File(path.join(testFilesDir.path, 'file1.txt'))
      ..writeAsStringSync('Hello, AirCrypt! ' * 1000);
    final file2 = File(path.join(testFilesDir.path, 'image.bin'))
      ..writeAsBytesSync(List<int>.generate(200000, (i) => i % 256));

    final senderToReceiver = StreamController<ProtocolMessage>.broadcast();
    final receiverToSender = StreamController<ProtocolMessage>.broadcast();

    final receiver = TransferReceiver(
      temporaryDirectory: tempDir,
      receivedDirectory: receivedDir,
      repository: receiverRepository,
      manager: receiverManager,
    );

    final sender = TransferSender(
      repository: senderRepository,
      manager: senderManager,
      chunkSize: 32 * 1024,
    );

    senderToReceiver.stream.listen((msg) async {
      if (msg.type == MessageType.transferRequest) {
        final payload = JsonPayload.decode(msg.payload);
        final request = TransferRequest.fromJson(payload);

        receiverToSender.add(
          ProtocolMessage(
            type: MessageType.transferAccept,
            payload: JsonPayload.encode({
              'transferId': request.transferId,
              'accepted': true,
            }),
          ),
        );
      } else {
        await receiver.handleMessage(
          msg,
          (reply) async {
            receiverToSender.add(reply);
          },
          senderDeviceId: 'sender_1',
          senderDeviceName: 'Sender Laptop',
        );
      }
    });

    final sendFuture = sender.sendTransfer(
      transferId: 'transfer_e2e_001',
      senderDeviceId: 'sender_1',
      senderDeviceName: 'Sender Laptop',
      receiverDeviceId: 'receiver_1',
      receiverDeviceName: 'Receiver Phone',
      files: [file1, file2],
      incomingMessages: receiverToSender.stream,
      sendMessage: (msg) async {
        senderToReceiver.add(msg);
      },
    );

    await sendFuture;

    final receivedFile1 = File(path.join(receivedDir.path, 'file1.txt'));
    final receivedFile2 = File(path.join(receivedDir.path, 'image.bin'));

    expect(await receivedFile1.exists(), isTrue);
    expect(await receivedFile2.exists(), isTrue);
    expect(
      await receivedFile1.readAsString(),
      equals(await file1.readAsString()),
    );
    expect(
      await receivedFile2.readAsBytes(),
      equals(await file2.readAsBytes()),
    );

    final senderTransfers = await senderRepository.getAllTransfers();
    expect(senderTransfers.length, equals(1));
    expect(senderTransfers.first.status, equals(TransferStatus.completed));

    final receiverTransfers = await receiverRepository.getAllTransfers();
    expect(receiverTransfers.length, equals(1));
    expect(receiverTransfers.first.status, equals(TransferStatus.completed));

    await senderToReceiver.close();
    await receiverToSender.close();
  });

  test('End-to-end file transfer rejection', () async {
    final file = File(path.join(testFilesDir.path, 'declined.pdf'))
      ..writeAsStringSync('Secret contents');

    final senderToReceiver = StreamController<ProtocolMessage>.broadcast();
    final receiverToSender = StreamController<ProtocolMessage>.broadcast();

    final sender = TransferSender(
      repository: senderRepository,
      manager: senderManager,
    );

    senderToReceiver.stream.listen((msg) async {
      if (msg.type == MessageType.transferRequest) {
        final payload = JsonPayload.decode(msg.payload);
        final request = TransferRequest.fromJson(payload);

        receiverToSender.add(
          ProtocolMessage(
            type: MessageType.transferReject,
            payload: JsonPayload.encode({
              'transferId': request.transferId,
              'accepted': false,
            }),
          ),
        );
      }
    });

    await sender.sendTransfer(
      transferId: 'transfer_e2e_002',
      senderDeviceId: 'sender_1',
      senderDeviceName: 'Sender Laptop',
      receiverDeviceId: 'receiver_1',
      receiverDeviceName: 'Receiver Phone',
      files: [file],
      incomingMessages: receiverToSender.stream,
      sendMessage: (msg) async {
        senderToReceiver.add(msg);
      },
    );

    final senderTransfers = await senderRepository.getAllTransfers();
    expect(senderTransfers.length, equals(1));
    expect(senderTransfers.first.status, equals(TransferStatus.rejected));

    await senderToReceiver.close();
    await receiverToSender.close();
  });
}
