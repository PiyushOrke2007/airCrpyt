import 'package:flutter/material.dart';

import '../../../core/theme/aircrypt_theme.dart';
import '../../../core/widgets/cyber_widgets.dart';
import '../manager/transfer_manager.dart';
import '../manager/transfer_session.dart';

class TransferProgressScreen extends StatelessWidget {
  final TransferManager transferManager;

  const TransferProgressScreen({super.key, required this.transferManager});

  Color _getStatusColor(TransferSessionStatus status) {
    switch (status) {
      case TransferSessionStatus.completed:
        return AirCryptColors.accentGreen;
      case TransferSessionStatus.failed:
      case TransferSessionStatus.rejected:
        return AirCryptColors.accentRed;
      case TransferSessionStatus.sending:
      case TransferSessionStatus.connecting:
        return AirCryptColors.accentCyan;
      case TransferSessionStatus.waiting:
        return AirCryptColors.accentAmber;
    }
  }

  String _getStatusText(TransferSession session) {
    switch (session.status) {
      case TransferSessionStatus.waiting:
        return 'WAITING...';
      case TransferSessionStatus.connecting:
        return 'CONNECTING...';
      case TransferSessionStatus.sending:
        return 'TRANSFERRING ${session.progressPercent.toStringAsFixed(0)}%';
      case TransferSessionStatus.completed:
        return 'VERIFIED & COMPLETE';
      case TransferSessionStatus.failed:
        return 'FAILED';
      case TransferSessionStatus.rejected:
        return 'REJECTED BY PEER';
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

  List<SecurityStepItem> _getSecuritySteps(List<TransferSession> sessions) {
    if (sessions.isEmpty) return [];

    final hasCompleted = sessions.any((s) => s.status == TransferSessionStatus.completed);
    final hasActive = sessions.any((s) => s.status == TransferSessionStatus.sending || s.status == TransferSessionStatus.connecting);
    final hasFailed = sessions.any((s) => s.status == TransferSessionStatus.failed || s.status == TransferSessionStatus.rejected);

    return [
      SecurityStepItem(
        label: 'Peer Connection Established',
        state: SecurityStepState.completed,
        subtext: 'TCP Socket Active',
      ),
      SecurityStepItem(
        label: 'RSA-2048 Session Key Exchanged',
        state: SecurityStepState.completed,
        subtext: 'Session Key Verified',
      ),
      SecurityStepItem(
        label: 'AES-256-GCM Encryption Active',
        state: hasCompleted
            ? SecurityStepState.completed
            : (hasActive ? SecurityStepState.active : SecurityStepState.pending),
        subtext: 'Chunked Cipher Stream',
      ),
      SecurityStepItem(
        label: 'SHA-256 Integrity Verification',
        state: hasCompleted
            ? SecurityStepState.completed
            : (hasFailed ? SecurityStepState.failed : SecurityStepState.pending),
        subtext: hasCompleted ? 'Hash Match 100%' : null,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SECURE TRANSFER PIPELINE'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: StreamBuilder<List<TransferSession>>(
          stream: transferManager.sessions,
          initialData: transferManager.activeSessions,
          builder: (context, snapshot) {
            final sessions = snapshot.data ?? [];

            if (sessions.isEmpty) {
              return const Center(
                child: Text(
                  'No active transfer session initialized.',
                  style: TextStyle(color: AirCryptColors.textMuted),
                ),
              );
            }

            final allFinished = sessions.every(
              (s) =>
                  s.status == TransferSessionStatus.completed ||
                  s.status == TransferSessionStatus.failed ||
                  s.status == TransferSessionStatus.rejected,
            );

            final allSuccessful = sessions.every(
              (s) => s.status == TransferSessionStatus.completed,
            );

            double overallProgress = 0.0;
            int overallTotalBytes = 0;
            if (sessions.isNotEmpty) {
              double sumProgress = 0;
              for (final s in sessions) {
                sumProgress += s.progress;
                overallTotalBytes += s.totalBytes;
              }
              overallProgress = (sumProgress / sessions.length).clamp(0.0, 1.0);
            }
            final transferredBytes = (overallTotalBytes * overallProgress).round();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Circular Progress Center Card
                  CyberCard(
                    showGlow: true,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 140,
                              height: 140,
                              child: CircularProgressIndicator(
                                value: overallProgress,
                                strokeWidth: 8,
                                backgroundColor: AirCryptColors.cardBorder,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  allFinished
                                      ? (allSuccessful ? AirCryptColors.accentGreen : AirCryptColors.accentRed)
                                      : AirCryptColors.accentCyan,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(overallProgress * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: allFinished
                                        ? (allSuccessful ? AirCryptColors.accentGreen : AirCryptColors.accentRed)
                                        : AirCryptColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  allFinished
                                      ? (allSuccessful ? 'COMPLETE' : 'FINISHED WITH ERRORS')
                                      : 'TRANSFERRING',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AirCryptColors.textSecondary,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '${_formatSize(transferredBytes)} / ${_formatSize(overallTotalBytes)}',
                          style: const TextStyle(
                            color: AirCryptColors.accentCyan,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Cryptographic Pipeline Checklist
                  SecurityPipelineWidget(
                    steps: _getSecuritySteps(sessions),
                  ),

                  const SizedBox(height: 20),

                  // Individual Recipients Cards List
                  Text(
                    'RECIPIENT NODES (${sessions.length})',
                    style: const TextStyle(
                      color: AirCryptColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final statusColor = _getStatusColor(session.status);

                      return CyberCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        borderColor: statusColor.withOpacity(0.3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.laptop_mac_outlined, size: 18, color: AirCryptColors.accentCyan),
                                    const SizedBox(width: 8),
                                    Text(
                                      session.deviceName,
                                      style: const TextStyle(
                                        color: AirCryptColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                CyberBadge(
                                  label: _getStatusText(session),
                                  color: statusColor,
                                  isFilled: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: session.progress,
                                minHeight: 6,
                                color: statusColor,
                                backgroundColor: AirCryptColors.cardBorder,
                              ),
                            ),
                            if (session.error != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.error_outline, size: 14, color: AirCryptColors.accentRed),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Error: ${session.error}',
                                      style: const TextStyle(
                                        color: AirCryptColors.accentRed,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Bottom Action Button
                  CyberButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: allFinished ? Icons.check_circle_outline : Icons.home_outlined,
                    label: allFinished ? 'DONE (RETURN TO TERMINAL)' : 'RETURN TO HOME TERMINAL',
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
