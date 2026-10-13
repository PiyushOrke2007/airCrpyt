import 'package:flutter/material.dart';

import '../../../../core/theme/aircrypt_theme.dart';

class DiscoveryStatusBar extends StatelessWidget {
  final String status;
  final VoidCallback onClose;

  const DiscoveryStatusBar({
    super.key,
    required this.status,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AirCryptColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AirCryptColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: AirCryptColors.accentCyan,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status,
              style: const TextStyle(
                color: AirCryptColors.accentCyan,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Icon(
              Icons.close,
              size: 18,
              color: AirCryptColors.accentCyan,
            ),
          ),
        ],
      ),
    );
  }
}
