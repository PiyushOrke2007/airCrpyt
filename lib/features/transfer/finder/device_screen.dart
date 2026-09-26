import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/database/transfer_repository.dart';
import '../../../../core/services/local_device_service.dart';
import '../manager/transfer_manager.dart';
import '../manager/transfer_sender.dart';
import 'models/discovered_device.dart';
import '../progress/transfer_progress_screen.dart';
import 'services/connection_handler.dart';
import '../tcp_client.dart';
import '../widgets/incoming_transfer_dialog.dart';
import 'widgets/device_list_item.dart';
import 'widgets/discovery_status_bar.dart';

class DeviceScreen extends StatefulWidget {
  final List<File>? selectedFiles;

  const DeviceScreen({super.key, this.selectedFiles});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  late final ConnectionHandler _handler;

  List<DiscoveredDevice> _devices = [];
  final Set<String> _selectedDeviceIds = {};
  final Set<String> _processedTransferIds = {};
  bool _isInitializing = true;
  String? _currentStatus;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _handler = ConnectionHandler(
      onDevicesChanged: (devices) {
        if (!mounted) return;
        setState(() {
          _devices = devices;
          _selectedDeviceIds.removeWhere(
            (id) => !_devices.any(
              (d) => d.id == id && d.status == DeviceStatus.online,
            ),
          );
        });
      },
      onInitializingChanged: (init) => setState(() => _isInitializing = init),
      onStatusChanged: (status) => setState(() => _currentStatus = status),
      onError: _showError,
      onIncomingConnection: _handleIncomingRequest,
      onIncomingTransferRequest: _handleIncomingTransferRequest,
    );
    _handler.start();
  }

  void _handleIncomingTransferRequest(
    String transferId,
    String senderName,
    int fileCount,
    int totalSize,
    Future<void> Function(bool accepted) replyCallback,
  ) {
    if (!mounted || _processedTransferIds.contains(transferId)) return;
    _processedTransferIds.add(transferId);

    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => IncomingTransferDialog(
        transferId: transferId,
        senderName: senderName,
        fileCount: fileCount,
        totalSize: totalSize,
      ),
    ).then((accepted) => replyCallback(accepted ?? false));
  }

  void _handleIncomingRequest(
    String senderName,
    Future<void> Function(bool accepted) replyCallback,
  ) {
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  List<DiscoveredDevice> get _onlineDevices =>
      _devices.where((d) => d.status == DeviceStatus.online).toList();

  bool get _isAllSelected =>
      _onlineDevices.isNotEmpty &&
      _onlineDevices.every((d) => _selectedDeviceIds.contains(d.id));

  bool get _isSomeSelected =>
      _onlineDevices.any((d) => _selectedDeviceIds.contains(d.id));

  bool? get _selectAllValue =>
      _isAllSelected ? true : (_isSomeSelected ? null : false);

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (_isAllSelected) {
        _selectedDeviceIds.clear();
      } else {
        _selectedDeviceIds.addAll(_onlineDevices.map((d) => d.id));
      }
    });
  }

  void _toggleDeviceSelection(String deviceId, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedDeviceIds.add(deviceId);
      } else {
        _selectedDeviceIds.remove(deviceId);
      }
    });
  }

  Future<void> _startTransfer() async {
    final files = widget.selectedFiles;
    if (files == null || files.isEmpty) {
      _showError('No files selected.');
      return;
    }

    final targetDevices = _onlineDevices
        .where((d) => _selectedDeviceIds.contains(d.id))
        .toList();

    if (targetDevices.isEmpty) {
      _showError('Select at least one online device.');
      return;
    }

    setState(() => _isSending = true);

    final localDevice = await LocalDeviceService().getLocalDevice();
    final transferManager = TransferManager();
    final repository = TransferRepository();

    final sendFutures = <Future<void>>[];

    for (final device in targetDevices) {
      final future = () async {
        final tcpClient = TcpClient();
        try {
          await tcpClient.connect(host: device.ipAddress, port: device.port);
          final transferId =
              'trans_${DateTime.now().millisecondsSinceEpoch}_${device.id}';

          final sender = TransferSender(
            repository: repository,
            manager: transferManager,
          );

          await sender.sendTransfer(
            transferId: transferId,
            senderDeviceId: localDevice.deviceId,
            senderDeviceName: localDevice.deviceName,
            receiverDeviceId: device.id,
            receiverDeviceName: device.name,
            files: files,
            incomingMessages: tcpClient.messages,
            sendMessage: (msg) => tcpClient.sendMessage(msg),
          );
        } catch (e) {
          debugPrint('Error sending transfer to ${device.name}: $e');
        } finally {
          await tcpClient.dispose();
        }
      }();

      sendFutures.add(future);
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TransferProgressScreen(transferManager: transferManager),
        ),
      );
    }

    await Future.wait(sendFutures);
  }

  @override
  void dispose() {
    _handler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileCount = widget.selectedFiles?.length ?? 0;
    final selectedDeviceCount = _selectedDeviceIds.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(fileCount > 0 ? 'Select Recipients' : 'Available Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _isInitializing
                ? null
                : () => _handler.reloadDiscovery(),
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
            if (_onlineDevices.isNotEmpty)
              CheckboxListTile(
                tristate: true,
                value: _selectAllValue,
                onChanged: _toggleSelectAll,
                title: const Text(
                  'Select All Devices',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '$selectedDeviceCount of ${_onlineDevices.length} selected',
                ),
              ),
            const Divider(height: 1),
            Expanded(child: _buildBody()),
            if (fileCount > 0)
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: selectedDeviceCount == 0 || _isSending
                      ? null
                      : _startTransfer,
                  icon: const Icon(Icons.send),
                  label: Text(
                    _isSending
                        ? 'Sending...'
                        : 'Send $fileCount file${fileCount == 1 ? '' : 's'} to $selectedDeviceCount device${selectedDeviceCount == 1 ? '' : 's'}',
                  ),
                ),
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
      return const Center(child: Text('No devices found nearby.'));
    }

    return ListView.builder(
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final isSelected = _selectedDeviceIds.contains(device.id);

        return DeviceListItem(
          device: device,
          isSelected: isSelected,
          onSelectionChanged: (val) => _toggleDeviceSelection(device.id, val),
        );
      },
    );
  }
}
