import 'package:flutter/material.dart';

import '../../core/database/database_service.dart';
import '../../core/models/transfer.dart';

class TransferHistoryScreen extends StatefulWidget {
  const TransferHistoryScreen({
    super.key,
  });

  @override
  State<TransferHistoryScreen> createState() =>
      _TransferHistoryScreenState();
}

class _TransferHistoryScreenState
    extends State<TransferHistoryScreen> {
  final DatabaseService _databaseService =
  DatabaseService();

  List<Transfer> _transfers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransfers();
  }

  Future<void> _loadTransfers() async {
    final database =
    await _databaseService.database;

    final rows = await database.query(
      'transfers',
      orderBy: 'created_at DESC',
    );

    final transfers = rows.map((row) {
      return Transfer(
        id: row['id']! as String,
        type: TransferType.values.byName(
          row['type']! as String,
        ),
        status: TransferStatus.values.byName(
          row['status']! as String,
        ),
        peerDeviceId:
        row['peer_device_id']! as String,
        peerDeviceName:
        row['peer_device_name']! as String,
        createdAt: DateTime.parse(
          row['created_at']! as String,
        ),
        completedAt: row['completed_at'] == null
            ? null
            : DateTime.parse(
          row['completed_at']! as String,
        ),
        totalSize:
        row['total_size']! as int,
      );
    }).toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _transfers = transfers;
      _isLoading = false;
    });
  }

  String _statusText(TransferStatus status) {
    switch (status) {
      case TransferStatus.requesting:
        return 'Requesting';

      case TransferStatus.waitingForAcceptance:
        return 'Waiting for acceptance';

      case TransferStatus.verifying:
        return 'Verifying';

      case TransferStatus.checkingStorage:
        return 'Checking storage';

      case TransferStatus.accepted:
        return 'Accepted';

      case TransferStatus.transferring:
        return 'Transferring';

      case TransferStatus.paused:
        return 'Paused';

      case TransferStatus.resuming:
        return 'Resuming';

      case TransferStatus.verifyingFile:
        return 'Verifying file';

      case TransferStatus.completed:
        return 'Completed';

      case TransferStatus.rejected:
        return 'Rejected';

      case TransferStatus.cancelled:
        return 'Cancelled';

      case TransferStatus.failed:
        return 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer History'),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _transfers.isEmpty
          ? const Center(
        child: Text(
          'No transfers yet.',
        ),
      )
          : ListView.builder(
        itemCount: _transfers.length,
        itemBuilder: (context, index) {
          final transfer =
          _transfers[index];

          final icon =
          transfer.type ==
              TransferType.send
              ? Icons.upload
              : Icons.download;

          return ListTile(
            leading: Icon(icon),
            title: Text(
              transfer.peerDeviceName,
            ),
            subtitle: Text(
              _statusText(
                transfer.status,
              ),
            ),
          );
        },
      ),
    );
  }
}