import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/services/local_device_service.dart';
import '../models/discovered_device.dart';
import '../../protocol/message_type.dart';
import '../../protocol/protocol_message.dart';
import '../../tcp_client.dart';
import '../../tcp_server.dart';
import '../udp_discovery_service.dart';

class ConnectionHandler {
  final UdpDiscoveryService _udpDiscoveryService = UdpDiscoveryService();
  final TcpServer _tcpServer = TcpServer();
  TcpClient? _tcpClient;

  StreamSubscription<List<DiscoveredDevice>>? _udpSubscription;
  StreamSubscription? _tcpServerSubscription;
  StreamSubscription<ProtocolMessage>? _tcpClientSubscription;

  final void Function(List<DiscoveredDevice>) onDevicesChanged;
  final void Function(bool) onInitializingChanged;
  final void Function(String?) onStatusChanged;
  final void Function(String) onError;
  final void Function(String senderName, Future<void> Function(bool accepted) replyCallback) onIncomingConnection;

  ConnectionHandler({
    required this.onDevicesChanged,
    required this.onInitializingChanged,
    required this.onStatusChanged,
    required this.onError,
    required this.onIncomingConnection,
  });

  Future<void> start() async {
    onInitializingChanged(true);

    try {
      final port = await _tcpServer.start(port: 0);
      
      _tcpServerSubscription = _tcpServer.messages.listen((incomingMessage) {
        _handleIncomingConnection(incomingMessage);
      }, onError: (error) {
        onError('Server Error: $error');
      });

      await _udpDiscoveryService.startDiscovery(tcpPort: port);

      _udpSubscription = _udpDiscoveryService.devicesStream.listen((deviceList) {
        onDevicesChanged(deviceList);
        onInitializingChanged(false);
      }, onError: (error) {
        onError('Discovery Error: $error');
      });

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

      _tcpClientSubscription = _tcpClient!.messages.listen((message) {
        if (message.type == MessageType.helloResponse && message.textPayload == 'HELLO_ACK') {
          onStatusChanged('Connected to ${device.name}');
        }
      }, onError: (error) {
        onStatusChanged('Connection failed');
      }, onDone: () {
        // Can be handled if needed
      });

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
    _udpDiscoveryService.dispose();
    _tcpServer.dispose();
  }
}
