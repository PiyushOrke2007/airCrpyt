import 'package:flutter/material.dart';
import '../models/discovered_device.dart';

class DeviceListItem extends StatelessWidget {
  final DiscoveredDevice device;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;
  final VoidCallback? onTap;

  const DeviceListItem({
    super.key,
    required this.device,
    this.isSelected = false,
    this.onSelectionChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = device.status == DeviceStatus.online;

    if (onSelectionChanged != null) {
      return CheckboxListTile(
        enabled: isOnline,
        value: isSelected,
        onChanged: isOnline ? onSelectionChanged : null,
        secondary: Icon(
          isOnline ? Icons.devices : Icons.devices_other,
          color: isOnline ? Colors.green : Colors.grey,
        ),
        title: Text(device.name),
        subtitle: Text(
          isOnline ? 'Online (${device.ipAddress})' : 'Offline',
          style: TextStyle(
            color: isOnline ? Colors.green : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

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
      trailing: isOnline ? const Icon(Icons.chevron_right) : null,
      onTap: isOnline ? onTap : null,
    );
  }
}
