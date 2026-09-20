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
