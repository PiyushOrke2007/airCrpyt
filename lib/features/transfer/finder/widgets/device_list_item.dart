import 'package:flutter/material.dart';

import '../../../../core/theme/aircrypt_theme.dart';
import '../../../../core/widgets/cyber_widgets.dart';
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

    final leadingWidget = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isOnline
            ? AirCryptColors.accentCyan.withOpacity(0.12)
            : AirCryptColors.textMuted.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: isOnline
              ? AirCryptColors.accentCyan.withOpacity(0.5)
              : AirCryptColors.textMuted.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: Icon(
        isOnline ? Icons.devices : Icons.phonelink_off_outlined,
        color: isOnline ? AirCryptColors.accentCyan : AirCryptColors.textMuted,
        size: 22,
      ),
    );

    if (onSelectionChanged != null) {
      return CyberCard(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        borderColor: isSelected
            ? AirCryptColors.accentCyan
            : (isOnline ? AirCryptColors.accentCyan.withOpacity(0.2) : AirCryptColors.cardBorder),
        showGlow: isSelected,
        child: CheckboxListTile(
          enabled: isOnline,
          value: isSelected,
          onChanged: isOnline ? onSelectionChanged : null,
          secondary: leadingWidget,
          activeColor: AirCryptColors.accentCyan,
          checkColor: AirCryptColors.bgDark,
          title: Text(
            device.name,
            style: const TextStyle(
              color: AirCryptColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          subtitle: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? AirCryptColors.accentGreen : AirCryptColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isOnline ? 'Online (${device.ipAddress})' : 'Offline',
                style: TextStyle(
                  color: isOnline ? AirCryptColors.accentGreen : AirCryptColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CyberCard(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      borderColor: isOnline ? AirCryptColors.accentCyan.withOpacity(0.25) : AirCryptColors.cardBorder,
      onTap: isOnline ? onTap : null,
      child: Row(
        children: [
          leadingWidget,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                    color: AirCryptColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    CyberBadge(
                      label: isOnline ? 'ONLINE' : 'OFFLINE',
                      color: isOnline ? AirCryptColors.accentGreen : AirCryptColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      device.ipAddress,
                      style: const TextStyle(
                        color: AirCryptColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isOnline)
            const Icon(
              Icons.chevron_right,
              color: AirCryptColors.accentCyan,
            ),
        ],
      ),
    );
  }
}
