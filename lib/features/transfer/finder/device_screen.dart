import 'package:flutter/material.dart';
import 'models/discovered_device.dart';
import 'services/connection_handler.dart';
import 'widgets/device_list_item.dart';
import 'widgets/discovery_status_bar.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  late final ConnectionHandler _handler;
  
  List<DiscoveredDevice> _devices = [];
  bool _isInitializing = true;
  String? _currentStatus;

  @override
  void initState() {
    super.initState();
    _handler = ConnectionHandler(
      onDevicesChanged: (devices) => setState(() => _devices = devices),
      onInitializingChanged: (init) => setState(() => _isInitializing = init),
      onStatusChanged: (status) => setState(() => _currentStatus = status),
      onError: _showError,
      onIncomingConnection: _handleIncomingRequest,
    );
    _handler.start();
  }

  void _handleIncomingRequest(String senderName, Future<void> Function(bool accepted) replyCallback) {
    if (!mounted) return;
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
    ).then((accepted) => replyCallback(accepted ?? false));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _handler.dispose();
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
            onPressed: _isInitializing ? null : () => _handler.reloadDiscovery(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentStatus != null)
              DiscoveryStatusBar(
                status: _currentStatus!,
                onClose: () => setState(() => _currentStatus = null),
              ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching for nearby devices...'),
          ],
        ),
      );
    }

    if (_devices.isEmpty) {
      return const Center(
        child: Text('No devices found nearby.'),
      );
    }

    return ListView.builder(
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return DeviceListItem(
          device: device,
          onTap: () => _handler.connectToDevice(device),
        );
      },
    );
  }
}
