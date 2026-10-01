import 'package:flutter/material.dart';

import '../manager/transfer_manager.dart';
import '../manager/transfer_session.dart';

class TransferProgressScreen extends StatelessWidget {
  final TransferManager transferManager;

  const TransferProgressScreen({super.key, required this.transferManager});

  Color _getStatusColor(TransferSessionStatus status) {
    switch (status) {
      case TransferSessionStatus.completed:
        return Colors.green;
      case TransferSessionStatus.failed:
      case TransferSessionStatus.rejected:
        return Colors.red;
      case TransferSessionStatus.sending:
      case TransferSessionStatus.connecting:
        return Colors.blue;
      case TransferSessionStatus.waiting:
        return Colors.orange;
    }
  }

  String _getStatusText(TransferSession session) {
    switch (session.status) {
      case TransferSessionStatus.waiting:
        return 'Waiting...';
      case TransferSessionStatus.connecting:
        return 'Connecting...';
      case TransferSessionStatus.sending:
        return 'Sending ${session.progressPercent.toStringAsFixed(1)}%';
      case TransferSessionStatus.completed:
        return 'Completed';
      case TransferSessionStatus.failed:
        return 'Failed';
      case TransferSessionStatus.rejected:
        return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transfer Progress'), centerTitle: true),
      body: SafeArea(
        child: StreamBuilder<List<TransferSession>>(
          stream: transferManager.sessions,
          initialData: transferManager.activeSessions,
          builder: (context, snapshot) {
            final sessions = snapshot.data ?? [];

            if (sessions.isEmpty) {
              return const Center(child: Text('No active transfers.'));
            }

            final allFinished = sessions.every(
              (s) =>
                  s.status == TransferSessionStatus.completed ||
                  s.status == TransferSessionStatus.failed ||
                  s.status == TransferSessionStatus.rejected,
            );

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Recipients (${sessions.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: sessions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final statusColor = _getStatusColor(session.status);

                        return Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      session.deviceName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        _getStatusText(session),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: statusColor.withAlpha(
                                        30,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: session.progress,
                                  color: statusColor,
                                  backgroundColor: Colors.grey.shade300,
                                ),
                                if (session.error != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Error: ${session.error}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: Icon(allFinished ? Icons.check : Icons.home),
                    label: Text(allFinished ? 'Done' : 'Back to Home'),
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
