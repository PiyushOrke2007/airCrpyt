import 'package:flutter/material.dart';

import '../../core/database/transfer_repository.dart';
import '../../core/models/transfer.dart';
import '../../core/theme/aircrypt_theme.dart';
import '../../core/widgets/cyber_widgets.dart';

class TransferHistoryScreen extends StatefulWidget {
  const TransferHistoryScreen({super.key});

  @override
  State<TransferHistoryScreen> createState() => _TransferHistoryScreenState();
}

class _TransferHistoryScreenState extends State<TransferHistoryScreen> {
  final TransferRepository _transferRepository = TransferRepository();

  List<Transfer> _transfers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransfers();
  }

  Future<void> _loadTransfers() async {
    final transfers = await _transferRepository.getAllTransfers();

    if (!mounted) return;

    setState(() {
      _transfers = transfers;
      _isLoading = false;
    });
  }

  String _statusText(TransferStatus status) {
    switch (status) {
      case TransferStatus.requesting:
        return 'REQUESTING';
      case TransferStatus.waitingForAcceptance:
        return 'WAITING ACCEPTANCE';
      case TransferStatus.verifying:
        return 'VERIFYING';
      case TransferStatus.checkingStorage:
        return 'CHECKING STORAGE';
      case TransferStatus.accepted:
        return 'ACCEPTED';
      case TransferStatus.transferring:
        return 'TRANSFERRING';
      case TransferStatus.paused:
        return 'PAUSED';
      case TransferStatus.resuming:
        return 'RESUMING';
      case TransferStatus.verifyingFile:
        return 'VERIFYING INTEGRITY';
      case TransferStatus.completed:
        return 'COMPLETED';
      case TransferStatus.rejected:
        return 'REJECTED';
      case TransferStatus.cancelled:
        return 'CANCELLED';
      case TransferStatus.failed:
        return 'FAILED';
    }
  }

  Color _statusColor(TransferStatus status) {
    switch (status) {
      case TransferStatus.completed:
        return AirCryptColors.accentGreen;
      case TransferStatus.rejected:
      case TransferStatus.failed:
      case TransferStatus.cancelled:
        return AirCryptColors.accentRed;
      default:
        return AirCryptColors.accentCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TRANSFER AUDIT LOG'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AirCryptColors.accentCyan),
              )
            : _transfers.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off_outlined,
                          size: 56,
                          color: AirCryptColors.textMuted,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'NO TRANSFER RECORDS LOGGED',
                          style: TextStyle(
                            color: AirCryptColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Historical session logs will be stored locally.',
                          style: TextStyle(
                            color: AirCryptColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transfers.length,
                    itemBuilder: (context, index) {
                      final transfer = _transfers[index];
                      final isSend = transfer.type == TransferType.send;
                      final clr = _statusColor(transfer.status);

                      return CyberCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        borderColor: clr.withOpacity(0.2),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSend
                                    ? AirCryptColors.accentCyan.withOpacity(0.12)
                                    : AirCryptColors.accentGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isSend ? Icons.upload_outlined : Icons.download_outlined,
                                color: isSend ? AirCryptColors.accentCyan : AirCryptColors.accentGreen,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transfer.peerDeviceName,
                                    style: const TextStyle(
                                      color: AirCryptColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  CyberBadge(
                                    label: _statusText(transfer.status),
                                    color: clr,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              isSend ? 'OUTBOUND' : 'INBOUND',
                              style: TextStyle(
                                color: isSend ? AirCryptColors.accentCyan : AirCryptColors.accentGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
