import 'dart:async';
import 'dart:io';

import '../../../core/database/transfer_repository.dart';
import '../../../core/models/transfer.dart';
import '../../../core/models/transfer_file.dart';
import '../io/chunk_reader.dart';
import '../protocol/chunk_metadata.dart';
import '../protocol/chunk_payload.dart';
import '../protocol/file_metadata.dart';
import '../protocol/json_payload.dart';
import '../protocol/message_type.dart';
import '../protocol/protocol_message.dart';
import '../protocol/transfer_metadata.dart';
import '../protocol/transfer_request.dart';
import 'transfer_manager.dart';
import 'transfer_session.dart';

class TransferSender {
  final TransferRepository repository;
  final TransferManager manager;
  final int chunkSize;

  TransferSender({
    required this.repository,
    required this.manager,
    this.chunkSize = ChunkReader.defaultChunkSize,
  });

  Future<void> sendTransfer({
    required String transferId,
    required String senderDeviceId,
    required String senderDeviceName,
    required String receiverDeviceId,
    required String receiverDeviceName,
    required List<File> files,
    required Stream<ProtocolMessage> incomingMessages,
    required Future<void> Function(ProtocolMessage message) sendMessage,
    Duration responseTimeout = const Duration(seconds: 30),
  }) async {
    final fileMetadatas = <FileMetadata>[];
    int totalSize = 0;

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileSize = await file.length();
      totalSize += fileSize;
      final totalChunks = fileSize == 0 ? 1 : (fileSize / chunkSize).ceil();
      final fileId = 'file_${transferId}_$i';

      fileMetadatas.add(
        FileMetadata(
          fileId: fileId,
          fileName: file.uri.pathSegments.last,
          fileSize: fileSize,
          totalChunks: totalChunks,
        ),
      );
    }

    final session = TransferSession(
      transferId: transferId,
      deviceId: receiverDeviceId,
      deviceName: receiverDeviceName,
      fileCount: files.length,
      totalBytes: totalSize,
      status: TransferSessionStatus.connecting,
    );

    manager.addSession(session);

    final dbTransfer = Transfer(
      id: transferId,
      type: TransferType.send,
      status: TransferStatus.requesting,
      peerDeviceId: receiverDeviceId,
      peerDeviceName: receiverDeviceName,
      createdAt: DateTime.now(),
      totalSize: totalSize,
    );

    await repository.insertTransfer(dbTransfer);

    for (int i = 0; i < files.length; i++) {
      final meta = fileMetadatas[i];
      final file = files[i];
      await repository.insertTransferFile(
        TransferFile(
          id: meta.fileId,
          transferId: transferId,
          fileName: meta.fileName,
          fileSize: meta.fileSize,
          status: TransferFileStatus.pending,
          sourcePath: file.path,
        ),
      );
    }

    final completer = Completer<bool>();
    final completionCompleter = Completer<void>();
    StreamSubscription<ProtocolMessage>? subscription;

    subscription = incomingMessages.listen(
      (message) {
        if (message.type == MessageType.transferAccept) {
          try {
            String? id;
            try {
              final payload = JsonPayload.decode(message.payload);
              id = payload['transferId'] as String?;
            } catch (_) {
              id = message.textPayload;
            }
            if (id == transferId || message.textPayload == transferId) {
              if (!completer.isCompleted) completer.complete(true);
            }
          } catch (_) {}
        } else if (message.type == MessageType.transferReject) {
          try {
            String? id;
            try {
              final payload = JsonPayload.decode(message.payload);
              id = payload['transferId'] as String?;
            } catch (_) {
              id = message.textPayload;
            }
            if (id == transferId || message.textPayload == transferId) {
              if (!completer.isCompleted) completer.complete(false);
            }
          } catch (_) {}
        } else if (message.type == MessageType.transferComplete) {
          try {
            final payload = JsonPayload.decode(message.payload);
            if (payload['transferId'] == transferId) {
              manager.updateSession(
                transferId,
                status: TransferSessionStatus.completed,
                progress: 1.0,
              );
              repository.updateTransferStatus(
                transferId,
                TransferStatus.completed,
              );
              if (!completionCompleter.isCompleted) {
                completionCompleter.complete();
              }
            }
          } catch (_) {}
        } else if (message.type == MessageType.transferFailed) {
          try {
            final payload = JsonPayload.decode(message.payload);
            if (payload['transferId'] == transferId) {
              final reason = payload['reason'] as String? ?? 'Transfer failed';
              manager.updateSession(
                transferId,
                status: TransferSessionStatus.failed,
                error: reason,
              );
              repository.updateTransferStatus(
                transferId,
                TransferStatus.failed,
              );
              if (!completionCompleter.isCompleted) {
                completionCompleter.completeError(StateError(reason));
              }
            }
          } catch (_) {}
        }
      },
      onError: (err) {
        if (!completer.isCompleted) completer.completeError(err);
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError('Connection closed before transfer handshake'),
          );
        }
      },
    );

    try {
      final request = TransferRequest(
        transferId: transferId,
        senderDeviceId: senderDeviceId,
        senderDeviceName: senderDeviceName,
        receiverDeviceId: receiverDeviceId,
        fileCount: files.length,
        totalSize: totalSize,
      );

      await sendMessage(
        ProtocolMessage(
          type: MessageType.transferRequest,
          payload: JsonPayload.encode(request.toJson()),
        ),
      );

      await repository.updateTransferStatus(
        transferId,
        TransferStatus.waitingForAcceptance,
      );

      final accepted = await completer.future.timeout(
        responseTimeout,
        onTimeout: () {
          throw TimeoutException('Transfer request timed out.');
        },
      );

      if (!accepted) {
        manager.updateSession(
          transferId,
          status: TransferSessionStatus.rejected,
          error: 'Transfer rejected by receiver',
        );
        await repository.updateTransferStatus(
          transferId,
          TransferStatus.rejected,
        );
        return;
      }

      manager.updateSession(transferId, status: TransferSessionStatus.sending);
      await repository.updateTransferStatus(
        transferId,
        TransferStatus.transferring,
      );

      final transferMeta = TransferMetadata(
        transferId: transferId,
        totalFiles: files.length,
        totalSize: totalSize,
        files: fileMetadatas,
      );

      await sendMessage(
        ProtocolMessage(
          type: MessageType.transferMetadata,
          payload: JsonPayload.encode(transferMeta.toJson()),
        ),
      );

      int totalBytesSent = 0;

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final meta = fileMetadatas[i];

        await repository.updateTransferFileStatus(
          meta.fileId,
          TransferFileStatus.transferring,
        );

        await sendMessage(
          ProtocolMessage(
            type: MessageType.fileStart,
            payload: JsonPayload.encode(meta.toJson()),
          ),
        );

        final reader = ChunkReader(file, chunkSize: chunkSize);
        int chunkIdx = 0;

        await for (final chunkData in reader.readAllChunks()) {
          final chunkMeta = ChunkMetadata(
            transferId: transferId,
            fileId: meta.fileId,
            chunkIndex: chunkIdx,
            totalChunks: meta.totalChunks,
            payloadLength: chunkData.length,
          );

          final payloadBytes = ChunkPayload(
            metadata: chunkMeta,
            data: chunkData,
          ).encode();

          await sendMessage(
            ProtocolMessage(type: MessageType.chunk, payload: payloadBytes),
          );

          chunkIdx++;
          totalBytesSent += chunkData.length;

          final currentProgress = totalSize == 0
              ? 1.0
              : (totalBytesSent / totalSize);
          manager.updateSession(transferId, progress: currentProgress);
        }

        await repository.updateTransferFileStatus(
          meta.fileId,
          TransferFileStatus.completed,
        );
      }

      await completionCompleter.future.timeout(
        responseTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Timed out waiting for receiver transfer completion confirmation.',
          );
        },
      );
    } catch (e) {
      manager.updateSession(
        transferId,
        status: TransferSessionStatus.failed,
        error: e.toString(),
      );
      await repository.updateTransferStatus(transferId, TransferStatus.failed);
      rethrow;
    } finally {
      await subscription.cancel();
    }
  }
}
