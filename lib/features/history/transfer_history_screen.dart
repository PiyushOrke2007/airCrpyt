import 'package:flutter/material.dart';

import '../../core/database/transfer_repository.dart';
import '../../core/models/transfer.dart';
import '../../core/models/transfer_file.dart';
import '../../core/theme/aircrypt_theme.dart';
import '../../core/widgets/cyber_widgets.dart';
import '../settings/settings_screen.dart';

class TransferHistoryScreen extends StatefulWidget {
  const TransferHistoryScreen({super.key});

  @override
  State<TransferHistoryScreen> createState() => _TransferHistoryScreenState();
}

class _TransferHistoryScreenState extends State<TransferHistoryScreen> {
  final TransferRepository _transferRepository = TransferRepository();

  List<Transfer> _transfers = [];
  Map<String, List<TransferFile>> _filesByTransferId = {};
  bool _isLoading = true;
  String? _errorMessage;
  TransferType? _filter;

  Future<void> _loadTransfers() async {
    try {
      final transfers = await _transferRepository.getAllTransfers();
      final fileEntries = await Future.wait(
        transfers.map(
          (transfer) async => MapEntry(
            transfer.id,
            await _transferRepository.getTransferFiles(transfer.id),
          ),
        ),
      );

      if (!mounted) return;
      setState(() {
        _transfers = transfers;
        _filesByTransferId = Map.fromEntries(fileEntries);
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load transfer history: $error';
        _isLoading = false;
      });
    }
  }

  String _statusText(TransferStatus status) {
    switch (status) {
      case TransferStatus.requesting:
      case TransferStatus.waitingForAcceptance:
      case TransferStatus.verifying:
      case TransferStatus.checkingStorage:
      case TransferStatus.accepted:
      case TransferStatus.transferring:
      case TransferStatus.paused:
      case TransferStatus.resuming:
      case TransferStatus.verifyingFile:
        return 'IN PROGRESS';
      case TransferStatus.completed:
        return 'SUCCESS';
      case TransferStatus.rejected:
        return 'DECLINED';
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
        return AirCryptColors.textPrimary;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _transferTime(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return TimeOfDay.fromDateTime(date).format(context);
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }
    return MaterialLocalizations.of(context).formatShortDate(date);
  }

  @override
  void initState() {
    super.initState();
    _loadTransfers();
  }

  @override
  Widget build(BuildContext context) {
    final visibleTransfers = _transfers
        .where((transfer) => _filter == null || transfer.type == _filter)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AIRCRYPT // HISTORY'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AirCryptColors.accentCyan,
                ),
              )
            : _errorMessage != null
            ? EmptyStateView(
                icon: Icons.error_outline,
                title: 'HISTORY UNAVAILABLE',
                message: _errorMessage!,
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '[ TRANSFER HISTORY ]',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'TOTAL: ${_transfers.length.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: AirCryptColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _FilterButton(
                          label: 'ALL',
                          selected: _filter == null,
                          onTap: () => setState(() => _filter = null),
                        ),
                        _FilterButton(
                          label: 'SENT',
                          selected: _filter == TransferType.send,
                          onTap: () =>
                              setState(() => _filter = TransferType.send),
                        ),
                        _FilterButton(
                          label: 'RECEIVED',
                          selected: _filter == TransferType.receive,
                          onTap: () =>
                              setState(() => _filter = TransferType.receive),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: visibleTransfers.isEmpty
                        ? EmptyStateView(
                            icon: Icons.history,
                            title: _transfers.isEmpty
                                ? 'NO TRANSFER RECORDS'
                                : 'NO MATCHING TRANSFERS',
                            message: _transfers.isEmpty
                                ? 'Your local transfer activity will appear here.'
                                : 'Choose another history filter.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: visibleTransfers.length,
                            itemBuilder: (context, index) {
                              final transfer = visibleTransfers[index];
                              final files =
                                  _filesByTransferId[transfer.id] ?? [];
                              final firstFile = files.isEmpty
                                  ? null
                                  : files.first;
                              final direction =
                                  transfer.type == TransferType.send
                                  ? 'SENT'
                                  : 'RCVD';
                              final peerLabel =
                                  transfer.type == TransferType.send
                                  ? 'TO:'
                                  : 'FROM:';
                              final statusColor = _statusColor(transfer.status);

                              return CyberCard(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.folder_zip_outlined,
                                          size: 17,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            firstFile?.fileName ??
                                                '${files.length} files',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '[ $direction ]',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${_formatSize(transfer.totalSize)}'
                                            '${files.length > 1 ? '  ·  ${files.length} files' : ''}',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color:
                                                  AirCryptColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _transferTime(transfer.createdAt),
                                          style: const TextStyle(fontSize: 9),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 18),
                                    Row(
                                      children: [
                                        Text(
                                          '$peerLabel ',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: AirCryptColors.textSecondary,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            transfer.peerDeviceName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        CyberBadge(
                                          label: _statusText(transfer.status),
                                          color: statusColor,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: OutlinedButton(
          onPressed: onTap,
          style:
              OutlinedButton.styleFrom(
                side: const BorderSide(color: AirCryptColors.textPrimary),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ).copyWith(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  final pressed = states.contains(WidgetState.pressed);
                  if (pressed) {
                    return selected
                        ? AirCryptColors.bgSurface
                        : AirCryptColors.textPrimary;
                  }
                  return selected
                      ? AirCryptColors.textPrimary
                      : Colors.transparent;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  final pressed = states.contains(WidgetState.pressed);
                  if (pressed) {
                    return selected
                        ? AirCryptColors.textPrimary
                        : AirCryptColors.bgSurface;
                  }
                  return selected
                      ? AirCryptColors.bgSurface
                      : AirCryptColors.textPrimary;
                }),
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              ),
          child: Text(
            '[ $label ]',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
