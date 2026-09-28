import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/database/transfer_repository.dart';
import '../../../../core/services/file_storage_service.dart';
import '../../../../core/services/local_device_service.dart';
import '../../manager/transfer_manager.dart';
import '../../manager/transfer_receiver.dart';
import '../../protocol/json_payload.dart';
import '../../protocol/message_type.dart';
import '../../protocol/protocol_message.dart';
import '../../protocol/transfer_request.dart';
import '../../tcp_client.dart';
import '../../tcp_server.dart';
import '../models/discovered_device.dart';
import '../udp_discovery_service.dart';

class ConnectionHandler {
  final UdpDiscoveryService _udpDiscoveryService = UdpDiscoveryService();
  final TcpServer _tcpServer = TcpServer();
  final TransferManager transferManager = TransferManager();
  TcpClient? _tcpClient;

  StreamSubscription<List<DiscoveredDevice>>? _udpSubscription;
  StreamSubscription? _tcpServerSubscription;
  StreamSubscription<ProtocolMessage>? _tcpClientSubscription;

  final void Function(List<DiscoveredDevice>) onDevicesChanged;
  final void Function(bool) onInitializingChanged;
  final void Function(String?) onStatusChanged;
  final void Function(String) onError;
  final void Function(
    String senderName,
    Future<void> Function(bool accepted) replyCallback,
  )
  onIncomingConnection;
  final void Function(
    String transferId,
    String senderName,
    int fileCount,
    int totalSize,
    Future<void> Function(bool accepted) replyCallback,
  )?
  onIncomingTransferRequest;

  ConnectionHandler({
    required this.onDevicesChanged,
    required this.onInitializingChanged,
    required this.onStatusChanged,
    required this.onError,
    required this.onIncomingConnection,
    this.onIncomingTransferRequest,
  });

  Future<void> start() async {
    onInitializingChanged(true);

    try {
      final port = await _tcpServer.start(port: 0);

      _tcpServerSubscription = _tcpServer.messages.listen(
        (incomingMessage) {
          _handleIncomingConnection(incomingMessage);
        },
        onError: (error) {
          onError('Server Error: $error');
        },
      );

      await _udpDiscoveryService.startDiscovery(tcpPort: port);

      _udpSubscription = _udpDiscoveryService.devicesStream.listen(
        (deviceList) {
          onDevicesChanged(deviceList);
          onInitializingChanged(false);
        },
        onError: (error) {
          onError('Discovery Error: $error');
        },
      );

      onInitializingChanged(false);
    } catch (e) {
      onError('Failed to start networking: $e');
      onInitializingChanged(false);
    }
  }

  void _handleIncomingConnection(dynamic incoming) {
    final message = incoming.message as ProtocolMessage;
    if (message.type == MessageType.hello) {
      final text = message.textPayload;
      final senderName = text.startsWith('HELLO_FROM_')
          ? text.replaceFirst('HELLO_FROM_', '')
          : 'Unknown Device';

      onIncomingConnection(senderName, (accepted) async {
        if (accepted) {
          try {
            await incoming.connection.sendMessage(
              ProtocolMessage.text(
                type: MessageType.helloResponse,
                text: 'HELLO_ACK',
              ),
            );
            onStatusChanged('Connected to $senderName');
          } catch (e) {
            onError('Failed to send handshake response: $e');
          }
        } else {
          try {
            await incoming.connection.close();
            onStatusChanged('Connection request rejected');
          } catch (e) {
            debugPrint('Error closing rejected connection: $e');
          }
        }
      });
    } else if (message.type == MessageType.transferRequest) {
      try {
        final payload = JsonPayload.decode(message.payload);
        final request = TransferRequest.fromJson(payload);

        onIncomingTransferRequest?.call(
          request.transferId,
          request.senderDeviceName,
          request.fileCount,
          request.totalSize,
          (accepted) async {
            if (accepted) {
              // IMPORTANT: install the receiver listener BEFORE sending
              // transferAccept. The sender starts sending transferMetadata
              // immediately after it receives transferAccept. Because
              // TcpConnection.messages is a broadcast stream, any message
              // emitted before this listener is attached is lost permanently.
              final storageService = FileStorageService();
              final tempDir = await storageService.getTemporaryDirectory();
              final receivedDir = await storageService.getReceivedDirectory();
              final repository = TransferRepository();

              final receiver = TransferReceiver(
                temporaryDirectory: tempDir,
                receivedDirectory: receivedDir,
                repository: repository,
                manager: transferManager,
              );

              // Stream listeners do not await an async callback. Without a
              // queue, several chunk messages emitted in one TCP read can be
              // processed concurrently. That can race with file finalization
              // and produce incomplete/corrupt output. Serialize them.
              Future<void> receiveQueue = Future<void>.value();

              incoming.connection.messages.listen(
                (msg) {
                  receiveQueue = receiveQueue
                      .then((_) async {
                        await receiver.handleMessage(
                          msg,
                          (reply) => incoming.connection.sendMessage(reply),
                          senderDeviceId: request.senderDeviceId,
                          senderDeviceName: request.senderDeviceName,
                        );
                      })
                      .catchError((Object e, StackTrace st) {
                        debugPrint('Receiver message handling failed: $e\n$st');
                      });
                },
                onError: (error, stackTrace) {
                  debugPrint('Receiver connection stream error: $error');
                },
              );

              debugPrint(
                'Receiving transfer ${request.transferId}; temporary=${tempDir.path}, received=${receivedDir.path}',
              );

              // The listener is now attached, so it is safe to acknowledge.
              await incoming.connection.sendMessage(
                ProtocolMessage(
                  type: MessageType.transferAccept,
                  payload: JsonPayload.encode({
                    'transferId': request.transferId,
                    'accepted': true,
                  }),
                ),
              );
            } else {
              await incoming.connection.sendMessage(
                ProtocolMessage(
                  type: MessageType.transferReject,
                  payload: JsonPayload.encode({
                    'transferId': request.transferId,
                    'accepted': false,
                  }),
                ),
              );
            }
          },
        );
      } catch (e) {
        debugPrint('Error parsing transferRequest in connection handler: $e');
      }
    }
  }

  Future<void> connectToDevice(DiscoveredDevice device) async {
    if (device.status == DeviceStatus.offline) {
      onError('Device is offline.');
      return;
    }

    await cleanupClient();
    onStatusChanged('Connecting to ${device.name}...');

    _tcpClient = TcpClient();

    try {
      await _tcpClient!.connect(host: device.ipAddress, port: device.port);

      _tcpClientSubscription = _tcpClient!.messages.listen(
        (message) {
          if (message.type == MessageType.helloResponse &&
              message.textPayload == 'HELLO_ACK') {
            onStatusChanged('Connected to ${device.name}');
          }
        },
        onError: (error) {
          onStatusChanged('Connection failed');
        },
        onDone: () {
          // Can be handled if needed
        },
      );

      final localDevice = await LocalDeviceService().getLocalDevice();
      await _tcpClient!.sendMessage(
        ProtocolMessage.text(
          type: MessageType.hello,
          text: 'HELLO_FROM_${localDevice.deviceName}',
        ),
      );
    } catch (e) {
      onStatusChanged('Connection failed');
    }
  }

  Future<void> reloadDiscovery() async {
    await _udpDiscoveryService.stopDiscovery();
    onDevicesChanged([]);
    onInitializingChanged(true);

    await _tcpServerSubscription?.cancel();
    await _tcpServer.stop();
    await start();
  }

  Future<void> cleanupClient() async {
    await _tcpClientSubscription?.cancel();
    _tcpClientSubscription = null;
    await _tcpClient?.disconnect();
    await _tcpClient?.dispose();
    _tcpClient = null;
  }

  void dispose() {
    _udpSubscription?.cancel();
    _tcpServerSubscription?.cancel();
    cleanupClient();
    transferManager.dispose();
    _udpDiscoveryService.dispose();
    _tcpServer.dispose();
  }
}
