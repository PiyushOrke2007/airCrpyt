import 'dart:async';

import '../manager/transfer_session.dart';

class TransferManager {
  final List<TransferSession> _sessions = [];

  final StreamController<List<TransferSession>> _sessionsController =
      StreamController<List<TransferSession>>.broadcast();

  Stream<List<TransferSession>> get sessions => _sessionsController.stream;

  List<TransferSession> get activeSessions => List.unmodifiable(_sessions);

  void addSession(TransferSession session) {
    _sessions.add(session);
    _emit();
  }

  void updateSession(
    String transferId, {
    TransferSessionStatus? status,
    double? progress,
    String? error,
  }) {
    final session = _sessions.firstWhere(
      (entry) => entry.transferId == transferId,
      orElse: () => throw StateError('Unknown transfer session: $transferId'),
    );

    if (status != null) {
      session.status = status;
    }

    if (progress != null) {
      session.progress = progress.clamp(0.0, 1.0);
    }

    if (error != null) {
      session.error = error;
    }

    _emit();
  }

  void removeSession(String transferId) {
    _sessions.removeWhere((entry) => entry.transferId == transferId);
    _emit();
  }

  void _emit() {
    if (!_sessionsController.isClosed) {
      _sessionsController.add(List.unmodifiable(_sessions));
    }
  }

  void dispose() {
    _sessionsController.close();
  }
}
