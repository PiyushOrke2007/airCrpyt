import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/aircrypt_theme.dart';
import '../../../core/widgets/cyber_widgets.dart';

class IncomingTransferDialog extends StatefulWidget {
  final String transferId;
  final String senderName;
  final int fileCount;
  final int totalSize;
  final Duration timeout;

  const IncomingTransferDialog({
    super.key,
    required this.transferId,
    required this.senderName,
    required this.fileCount,
    required this.totalSize,
    this.timeout = const Duration(seconds: 30),
  });

  @override
  State<IncomingTransferDialog> createState() => _IncomingTransferDialogState();
}

class _IncomingTransferDialogState extends State<IncomingTransferDialog> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timeout.inSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        Navigator.of(context).pop(false); // Reject on timeout
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressVal = _remainingSeconds / widget.timeout.inSeconds;

    return Dialog(
      backgroundColor: AirCryptColors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AirCryptColors.accentCyan.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AirCryptColors.accentCyan.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security,
                    color: AirCryptColors.accentCyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INCOMING TRANSFER',
                        style: TextStyle(
                          color: AirCryptColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Explicit authorization required',
                        style: TextStyle(
                          color: AirCryptColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Timer Badge Ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        value: progressVal,
                        strokeWidth: 2.5,
                        backgroundColor: AirCryptColors.cardBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _remainingSeconds < 10
                              ? AirCryptColors.accentRed
                              : AirCryptColors.accentCyan,
                        ),
                      ),
                    ),
                    Text(
                      '${_remainingSeconds}s',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AirCryptColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Transfer Payload Details Card
            CyberCard(
              padding: const EdgeInsets.all(16),
              borderColor: AirCryptColors.accentCyan.withOpacity(0.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.devices, size: 16, color: AirCryptColors.accentCyan),
                      const SizedBox(width: 8),
                      const Text(
                        'FROM SENDER:',
                        style: TextStyle(
                          color: AirCryptColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.senderName,
                          style: const TextStyle(
                            color: AirCryptColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.insert_drive_file_outlined, size: 16, color: AirCryptColors.accentCyan),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.fileCount} File${widget.fileCount == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: AirCryptColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      CyberBadge(
                        label: _formatSize(widget.totalSize),
                        color: AirCryptColors.accentCyan,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Explicit Security Consent Note
            Row(
              children: const [
                Icon(Icons.lock_outline, size: 14, color: AirCryptColors.accentGreen),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'No data will be transferred until you accept.',
                    style: TextStyle(
                      color: AirCryptColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: CyberButton(
                    label: 'DECLINE',
                    isPrimary: false,
                    isDanger: true,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CyberButton(
                    label: 'ACCEPT',
                    isPrimary: true,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
