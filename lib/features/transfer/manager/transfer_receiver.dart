import 'dart:async';
import 'dart:io';

import '../../../core/database/transfer_repository.dart';
import '../../../core/models/transfer.dart';
import '../../../core/models/transfer_file.dart';
import '../io/chunk_writer.dart';
import '../protocol/chunk_payload.dart';
import '../protocol/file_metadata.dart';
import '../protocol/json_payload.dart';
import '../protocol/message_type.dart';
import '../protocol/protocol_message.dart';
import '../protocol/transfer_metadata.dart';
import 'transfer_manager.dart';
import 'transfer_session.dart';

class _ActiveReceiveState {
  final TransferMetadata metadata;
  final String senderDeviceId;
  final String senderDeviceName;
  final Map<String, int> receivedBytesPerFile = {};
  final Set<String> completedFileIds = {};
  int totalBytesReceived = 0;

  _ActiveReceiveState({
    required this.metadata,
    required this.senderDeviceId,
    required this.senderDeviceName,
  });
}

class TransferReceiver {
  final Directory temporaryDirectory;
  final Directory receivedDirectory;
  final TransferRepository repository;
  final TransferManager manager;
  final ChunkWriter chunkWriter;

  final Map<String, _ActiveReceiveState> _activeReceives = {};

  TransferReceiver({
    required this.temporaryDirectory,
    required this.receivedDirectory,
    required this.repository,
    required this.manager,
  }) : chunkWriter = ChunkWriter(
         temporaryDirectory: temporaryDirectory,
         receivedDirectory: receivedDirectory,
       );

  Future<void> handleMessage(
    ProtocolMessage message,
    Future<void> Function(ProtocolMessage reply) sendMessage, {
    String senderDeviceId = 'unknown_sender',
    String senderDeviceName = 'Unknown Sender',
  }) async {
    try {
      if (message.type == MessageType.transferMetadata) {
        final payload = JsonPayload.decode(message.payload);
        final metadata = TransferMetadata.fromJson(payload);

        final state = _ActiveReceiveState(
          metadata: metadata,
          senderDeviceId: senderDeviceId,
          senderDeviceName: senderDeviceName,
        );
        _activeReceives[metadata.transferId] = state;

        final session = TransferSession(
          transferId: metadata.transferId,
          deviceId: senderDeviceId,
          deviceName: senderDeviceName,
          fileCount: metadata.totalFiles,
          totalBytes: metadata.totalSize,
          status: TransferSessionStatus.sending,
        );
        manager.addSession(session);

        final dbTransfer = Transfer(
          id: metadata.transferId,
          type: TransferType.receive,
          status: TransferStatus.transferring,
          peerDeviceId: senderDeviceId,
          peerDeviceName: senderDeviceName,
          createdAt: DateTime.now(),
          totalSize: metadata.totalSize,
        );
        await repository.insertTransfer(dbTransfer);

        for (final fileMeta in metadata.files) {
          await repository.insertTransferFile(
            TransferFile(
              id: fileMeta.fileId,
              transferId: metadata.transferId,
              fileName: fileMeta.fileName,
              fileSize: fileMeta.fileSize,
              status: TransferFileStatus.pending,
            ),
          );
        }
      } else if (message.type == MessageType.fileStart) {
        final payload = JsonPayload.decode(message.payload);
        final fileMeta = FileMetadata.fromJson(payload);

        _ActiveReceiveState? activeState;
        for (final candidate in _activeReceives.values) {
          if (candidate.metadata.files.any(
            (f) => f.fileId == fileMeta.fileId,
          )) {
            activeState = candidate;
            break;
          }
        }

        await repository.updateTransferFileStatus(
          fileMeta.fileId,
          TransferFileStatus.transferring,
        );

        // A zero-byte file produces no chunks from ChunkReader. Finalize it
        // here, otherwise the receiver waits forever for a chunk that can
        // never arrive and the sender eventually times out waiting for
        // transferComplete.
        if (fileMeta.fileSize == 0 && activeState != null) {
          final state = activeState;
          if (!state.completedFileIds.contains(fileMeta.fileId)) {
            final savedFile = await chunkWriter.finalizeFile(
              transferId: state.metadata.transferId,
              fileId: fileMeta.fileId,
              expectedLength: 0,
              fileName: fileMeta.fileName,
            );

            state.completedFileIds.add(fileMeta.fileId);
            await repository.updateTransferFileStatus(
              fileMeta.fileId,
              TransferFileStatus.completed,
              savedPath: savedFile.path,
            );

            if (state.completedFileIds.length == state.metadata.totalFiles) {
              await repository.updateTransferStatus(
                state.metadata.transferId,
                TransferStatus.completed,
              );
              manager.updateSession(
                state.metadata.transferId,
                status: TransferSessionStatus.completed,
                progress: 1.0,
              );
              await sendMessage(
                ProtocolMessage(
                  type: MessageType.transferComplete,
                  payload: JsonPayload.encode({
                    'transferId': state.metadata.transferId,
                  }),
                ),
              );
              _activeReceives.remove(state.metadata.transferId);
            }
          }
        }
      } else if (message.type == MessageType.chunk) {
        final chunkPayload = ChunkPayload.decode(message.payload);
        final chunkMeta = chunkPayload.metadata;
        final transferId = chunkMeta.transferId;

        final state = _activeReceives[transferId];
        if (state == null) {
          throw StateError(
            'Received chunk for unknown transferId: $transferId',
          );
        }

        final fileMeta = state.metadata.files.firstWhere(
          (f) => f.fileId == chunkMeta.fileId,
          orElse: () => throw StateError(
            'Unknown fileId ${chunkMeta.fileId} in transfer $transferId',
          ),
        );

        await chunkWriter.writeChunk(
          transferId: transferId,
          fileId: chunkMeta.fileId,
          chunkIndex: chunkMeta.chunkIndex,
          totalChunks: chunkMeta.totalChunks,
          data: chunkPayload.data,
          expectedLength: fileMeta.fileSize,
        );

        state.receivedBytesPerFile[chunkMeta.fileId] =
            (state.receivedBytesPerFile[chunkMeta.fileId] ?? 0) +
            chunkPayload.data.length;
        state.totalBytesReceived += chunkPayload.data.length;

        final totalSize = state.metadata.totalSize;
        final progress = totalSize == 0
            ? 1.0
            : (state.totalBytesReceived / totalSize);
        manager.updateSession(transferId, progress: progress);

        final fileReceivedBytes =
            state.receivedBytesPerFile[chunkMeta.fileId] ?? 0;
        if (fileReceivedBytes >= fileMeta.fileSize ||
            chunkMeta.chunkIndex == chunkMeta.totalChunks - 1) {
          if (!state.completedFileIds.contains(chunkMeta.fileId)) {
            state.completedFileIds.add(chunkMeta.fileId);
            final savedFile = await chunkWriter.finalizeFile(
              transferId: transferId,
              fileId: chunkMeta.fileId,
              expectedLength: fileMeta.fileSize,
              fileName: fileMeta.fileName,
            );

            await repository.updateTransferFileStatus(
              chunkMeta.fileId,
              TransferFileStatus.completed,
              savedPath: savedFile.path,
            );
          }
        }

        if (state.completedFileIds.length == state.metadata.totalFiles) {
          await repository.updateTransferStatus(
            transferId,
            TransferStatus.completed,
          );

          manager.updateSession(
            transferId,
            status: TransferSessionStatus.completed,
            progress: 1.0,
          );

          await sendMessage(
            ProtocolMessage(
              type: MessageType.transferComplete,
              payload: JsonPayload.encode({'transferId': transferId}),
            ),
          );

          _activeReceives.remove(transferId);
        }
      } else if (message.type == MessageType.transferCancel) {
        final payload = JsonPayload.decode(message.payload);
        final transferId = payload['transferId'] as String;

        _activeReceives.remove(transferId);
        await repository.updateTransferStatus(
          transferId,
          TransferStatus.cancelled,
        );
        manager.updateSession(
          transferId,
          status: TransferSessionStatus.failed,
          error: 'Transfer cancelled',
        );
      }
    } catch (e) {
      if (message.type == MessageType.chunk) {
        try {
          final chunkPayload = ChunkPayload.decode(message.payload);
          final transferId = chunkPayload.metadata.transferId;
          _activeReceives.remove(transferId);

          await repository.updateTransferStatus(
            transferId,
            TransferStatus.failed,
          );
          manager.updateSession(
            transferId,
            status: TransferSessionStatus.failed,
            error: e.toString(),
          );

          await sendMessage(
            ProtocolMessage(
              type: MessageType.transferFailed,
              payload: JsonPayload.encode({
                'transferId': transferId,
                'reason': e.toString(),
              }),
            ),
          );
        } catch (_) {}
      }
      rethrow;
    }
  }
}
