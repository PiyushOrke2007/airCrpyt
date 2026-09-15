import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/services/local_device_service.dart';

enum DeviceStatus { online, offline }

class DiscoveredDevice {
  final String id;
  final String name;
  final String ipAddress;
  final int port;
  final DeviceStatus status;
  final DateTime lastSeen;

  DiscoveredDevice({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.port,
    required this.status,
    required this.lastSeen,
  });

  DiscoveredDevice copyWith({
    DeviceStatus? status,
    DateTime? lastSeen,
    String? name,
  }) {
    return DiscoveredDevice(
      id: id,
      name: name ?? this.name,
      ipAddress: ipAddress,
      port: port,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

class UdpDiscoveryService {
  static const int udpPort = 5500;
  static const String magicString = 'AIRCRYPT_DISCOVERY';

  final LocalDeviceService _localDeviceService = LocalDeviceService();
  
  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  Timer? _timeoutTimer;

  final StreamController<List<DiscoveredDevice>> _devicesController =
      StreamController<List<DiscoveredDevice>>.broadcast();

  final Map<String, DiscoveredDevice> _discoveredDevices = {};

  Stream<List<DiscoveredDevice>> get devicesStream => _devicesController.stream;
  List<DiscoveredDevice> get currentDevices => _discoveredDevices.values.toList();

  Future<void> startDiscovery({required int tcpPort}) async {
    await stopDiscovery();

    _discoveredDevices.clear();
    _devicesController.add([]);

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, udpPort, reuseAddress: true);
      _socket?.broadcastEnabled = true;

      _socket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            _parseDiscoveryPacket(datagram);
          }
        }
      }, onError: (Object error) {
        debugPrint('UDP Socket error: $error');
      });

      final localDevice = await _localDeviceService.getLocalDevice();

      _broadcastTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _broadcastPresence(localDevice.deviceId, localDevice.deviceName, tcpPort);
      });

      _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _checkTimeouts();
      });
    } catch (e) {
      debugPrint('Failed to start UDP discovery: $e');
      _devicesController.addError(e);
    }
  }

  void _broadcastPresence(String deviceId, String deviceName, int tcpPort) {
    if (_socket == null) return;

    try {
      final payload = {
        'magic': magicString,
        'id': deviceId,
        'name': deviceName,
        'port': tcpPort,
      };

      final data = utf8.encode(jsonEncode(payload));
      
      _socket?.send(data, InternetAddress('255.255.255.255'), udpPort);
    } catch (e) {
      debugPrint('Error broadcasting UDP presence: $e');
    }
  }

  void _parseDiscoveryPacket(Datagram datagram) {
    try {
      final message = utf8.decode(datagram.data);
      final payload = jsonDecode(message) as Map<String, dynamic>;

      if (payload['magic'] != magicString) return;

      final String id = payload['id'] as String;
      final String name = payload['name'] as String;
      final int port = payload['port'] as int;
      final String ipAddress = datagram.address.address;

      _localDeviceService.getLocalDevice().then((localDevice) {
        if (id == localDevice.deviceId) return;

        final existing = _discoveredDevices[id];
        final now = DateTime.now();

        if (existing == null) {
          _discoveredDevices[id] = DiscoveredDevice(
            id: id,
            name: name,
            ipAddress: ipAddress,
            port: port,
            status: DeviceStatus.online,
            lastSeen: now,
          );
        } else {
          _discoveredDevices[id] = existing.copyWith(
            name: name,
            status: DeviceStatus.online,
            lastSeen: now,
          );
        }

        _devicesController.add(_discoveredDevices.values.toList());
      });
    } catch (e) {
      debugPrint('Error parsing UDP packet: $e');
    }
  }

  void _checkTimeouts() {
    final now = DateTime.now();
    bool changed = false;

    for (final id in _discoveredDevices.keys) {
      final device = _discoveredDevices[id]!;
      if (device.status == DeviceStatus.online &&
          now.difference(device.lastSeen) > const Duration(seconds: 3)) {
        _discoveredDevices[id] = device.copyWith(status: DeviceStatus.offline);
        changed = true;
      }
    }

    if (changed) {
      _devicesController.add(_discoveredDevices.values.toList());
    }
  }

  Future<void> stopDiscovery() async {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;

    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    _socket?.close();
    _socket = null;
  }

  Future<void> dispose() async {
    await stopDiscovery();
    await _devicesController.close();
  }
}
