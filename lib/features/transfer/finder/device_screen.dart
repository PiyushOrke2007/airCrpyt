import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/local_device_service.dart';
import '../protocol/message_type.dart';
import '../protocol/protocol_message.dart';
import '../tcp_client.dart';
import '../tcp_server.dart';
import 'udp_discovery_service.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final UdpDiscoveryService _udpDiscoveryService = UdpDiscoveryService();
  final TcpServer _tcpServer = TcpServer();
  
  TcpClient? _tcpClient;
  
  StreamSubscription<List<DiscoveredDevice>>? _udpSubscription;
  StreamSubscription? _tcpServerSubscription;
  StreamSubscription<ProtocolMessage>? _tcpClientSubscription;

  List<DiscoveredDevice> _devices = [];
  bool _isInitializing = true;
  String? _currentStatus;
  String? _activeDeviceName;

  @override
  void initState() {
    super.initState();
    _startServices();
  }

  Future<void> _startServices() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      // 1. Start TCP Server on an available port
      final port = await _tcpServer.start(port: 0); // 0 lets OS pick an available port
      
      // 2. Listen for incoming TCP connection requests (Receiver role)
      _tcpServerSubscription = _tcpServer.messages.listen((incomingMessage) {
        _handleIncomingConnection(incomingMessage);
      }, onError: (error) {
        _showError('Server Error: $error');
      });

      // 3. Start UDP Discovery, advertising our TCP port
      await _udpDiscoveryService.startDiscovery(tcpPort: port);

      // 4. Listen for discovered devices
      _udpSubscription = _udpDiscoveryService.devicesStream.listen((deviceList) {
        if (mounted) {
          setState(() {
            _devices = deviceList;
            _isInitializing = false;
          });
        }
      }, onError: (error) {
        _showError('Discovery Error: $error');
      });

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      _showError('Failed to start networking: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _handleIncomingConnection(dynamic incoming) {
    final message = incoming.message as ProtocolMessage;
    if (message.type == MessageType.hello) {
      final text = message.textPayload;
      final senderName = text.startsWith('HELLO_FROM_') 
          ? text.replaceFirst('HELLO_FROM_', '') 
          : 'Unknown Device';

      if (!mounted) return;

      // Show Authorization Dialog
      showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Connection Request'),
          content: Text('"$senderName" wants to connect.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Reject'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Accept'),
            ),
          ],
        ),
      ).then((accepted) async {
        if (accepted == true) {
          try {
            await incoming.connection.sendMessage(
              ProtocolMessage.text(
                type: MessageType.helloResponse,
                text: 'HELLO_ACK',
              ),
            );
            setState(() {
              _currentStatus = 'Connected to $senderName';
              _activeDeviceName = senderName;
            });
          } catch (e) {
            _showError('Failed to send handshake response: $e');
          }
        } else {
          try {
            await incoming.connection.close();
            setState(() {
              _currentStatus = 'Connection request rejected';
              _activeDeviceName = null;
            });
          } catch (e) {
            debugPrint('Error closing rejected connection: $e');
          }
        }
      });
    }
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    if (device.status == DeviceStatus.offline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device is offline.')),
      );
      return;
    }

    await _cleanupClient();

    setState(() {
      _currentStatus = 'Connecting to ${device.name}...';
      _activeDeviceName = device.name;
    });

    _tcpClient = TcpClient();

    try {
      await _tcpClient!.connect(host: device.ipAddress, port: device.port);

      _tcpClientSubscription = _tcpClient!.messages.listen((message) {
        if (message.type == MessageType.helloResponse && message.textPayload == 'HELLO_ACK') {
          setState(() {
            _currentStatus = 'Connected to ${device.name}';
          });
        }
      }, onError: (error) {
        setState(() {
          _currentStatus = 'Connection failed';
        });
      }, onDone: () {
        if (mounted && _currentStatus != null && _currentStatus!.contains('Connecting')) {
          setState(() {
            _currentStatus = 'Connection request rejected';
          });
        }
      });

      final localDevice = await LocalDeviceService().getLocalDevice();
      await _tcpClient!.sendMessage(
        ProtocolMessage.text(
          type: MessageType.hello,
          text: 'HELLO_FROM_${localDevice.deviceName}',
        ),
      );
    } catch (e) {
      setState(() {
        _currentStatus = 'Connection failed';
      });
    }
  }

  Future<void> _reloadDiscovery() async {
    await _udpDiscoveryService.stopDiscovery();
    setState(() {
      _devices.clear();
      _isInitializing = true;
    });
    
    if (_tcpServer.isRunning) {
      // Reuse the running server port
      final activeConnections = _tcpServer.activeConnections;
      for (final conn in activeConnections) {
        await conn.close();
      }
      // Re-advertise on the existing server's port
      await _udpDiscoveryService.startDiscovery(tcpPort: _tcpServer.activeConnections.isEmpty ? 5000 : 5000); 
      // Let's make it robust: we can just close and restart everything to be perfectly safe as per instruction 6
      await _tcpServerSubscription?.cancel();
      await _tcpServer.stop();
      await _startServices();
    } else {
      await _startServices();
    }
  }

  Future<void> _cleanupClient() async {
    await _tcpClientSubscription?.cancel();
    _tcpClientSubscription = null;
    await _tcpClient?.disconnect();
    await _tcpClient?.dispose();
    _tcpClient = null;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _resetStatus() {
    setState(() {
      _currentStatus = null;
      _activeDeviceName = null;
    });
  }

  @override
  void dispose() {
    _udpSubscription?.cancel();
    _tcpServerSubscription?.cancel();
    _cleanupClient();
    _udpDiscoveryService.dispose();
    _tcpServer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _isInitializing ? null : _reloadDiscovery,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentStatus != null)
              Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _currentStatus!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _resetStatus,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isInitializing
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Searching for nearby devices...'),
                        ],
                      ),
                    )
                  : _devices.isEmpty
                      ? const Center(
                          child: Text('No devices found nearby.'),
                        )
                      : ListView.builder(
                          itemCount: _devices.length,
                          itemBuilder: (context, index) {
                            final device = _devices[index];
                            final isOnline = device.status == DeviceStatus.online;
                            return ListTile(
                              leading: Icon(
                                isOnline ? Icons.devices : Icons.devices_other,
                                color: isOnline ? Colors.green : Colors.grey,
                              ),
                              title: Text(device.name),
                              subtitle: Text(
                                isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  color: isOnline ? Colors.green : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: isOnline
                                  ? const Icon(Icons.chevron_right)
                                  : null,
                              onTap: isOnline ? () => _connectToDevice(device) : null,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
