enum TransferSessionStatus {
  waiting,
  connecting,
  sending,
  finalizing,
  completed,
  failed,
  rejected,
}

class TransferSession {
  final String transferId;
  final String deviceId;
  final String deviceName;
  final int fileCount;
  final int totalBytes;
  final DateTime createdAt;

  TransferSessionStatus status;
  double progress;
  int bytesTransferred;
  double bytesPerSecond;
  String? error;

  DateTime? _lastUpdateTime;
  int _lastBytesTransferred = 0;

  TransferSession({
    required this.transferId,
    required this.deviceId,
    required this.deviceName,
    required this.fileCount,
    required this.totalBytes,
    this.status = TransferSessionStatus.waiting,
    this.progress = 0.0,
    this.bytesTransferred = 0,
    this.bytesPerSecond = 0.0,
    this.error,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progressPercent => progress.clamp(0.0, 1.0) * 100;

  void updateProgress({
    double? newProgress,
    int? newBytesTransferred,
    TransferSessionStatus? newStatus,
    String? newError,
  }) {
    final now = DateTime.now();

    if (newStatus != null) status = newStatus;
    if (newError != null) error = newError;

    if (newBytesTransferred != null) {
      bytesTransferred = newBytesTransferred;

      if (_lastUpdateTime != null) {
        final elapsedMs = now.difference(_lastUpdateTime!).inMilliseconds;
        if (elapsedMs >= 150) {
          final deltaBytes = bytesTransferred - _lastBytesTransferred;
          if (deltaBytes >= 0) {
            final instantSpeed = deltaBytes / (elapsedMs / 1000.0);
            bytesPerSecond = bytesPerSecond == 0.0
                ? instantSpeed
                : (bytesPerSecond * 0.7) + (instantSpeed * 0.3);
          }
          _lastUpdateTime = now;
          _lastBytesTransferred = bytesTransferred;
        }
      } else {
        _lastUpdateTime = now;
        _lastBytesTransferred = bytesTransferred;
      }

      if (bytesPerSecond == 0.0 && bytesTransferred > 0) {
        final totalElapsedSec =
            now.difference(createdAt).inMilliseconds / 1000.0;
        if (totalElapsedSec > 0.01) {
          bytesPerSecond = bytesTransferred / totalElapsedSec;
        }
      }
    } else if (newProgress != null) {
      bytesTransferred = (totalBytes * newProgress.clamp(0.0, 1.0)).round();
    }

    if (newProgress != null) {
      progress = newProgress.clamp(0.0, 1.0);
    } else if (totalBytes > 0) {
      progress = (bytesTransferred / totalBytes).clamp(0.0, 1.0);
    }

    if (status == TransferSessionStatus.completed) {
      progress = 1.0;
      bytesTransferred = totalBytes;
      bytesPerSecond = 0.0;
    }
  }

  int get remainingBytes =>
      (totalBytes - bytesTransferred).clamp(0, totalBytes);

  int? get estimatedSecondsRemaining {
    if (status == TransferSessionStatus.completed) return 0;
    if (bytesPerSecond <= 0 || bytesTransferred <= 0) return null;
    final seconds = (remainingBytes / bytesPerSecond).ceil();
    return seconds < 0 ? 0 : seconds;
  }

  static const int maxAllowedTransferSeconds = 60; // 1 minute

  bool get isExceedingTimeLimit {
    if (DateTime.now().difference(createdAt).inSeconds < 3) return false;
    final sec = estimatedSecondsRemaining;
    return sec != null && sec > maxAllowedTransferSeconds;
  }

  String get speedText {
    if (status == TransferSessionStatus.completed) return '0 B/s';
    if (bytesPerSecond <= 0) return '0 B/s';
    return formatSpeed(bytesPerSecond);
  }

  String get etaText {
    if (status == TransferSessionStatus.completed) return 'Complete';
    if (status == TransferSessionStatus.failed ||
        status == TransferSessionStatus.rejected) {
      return 'Stopped';
    }
    final sec = estimatedSecondsRemaining;
    if (sec == null) return 'Calculating...';
    return formatDuration(sec);
  }

  static String formatSpeed(double bytesPerSec) {
    if (bytesPerSec < 1024) return '${bytesPerSec.toStringAsFixed(0)} B/s';
    if (bytesPerSec < 1024 * 1024) {
      return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    if (bytesPerSec < 1024 * 1024 * 1024) {
      return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    return '${(bytesPerSec / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB/s';
  }

  static String formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '< 1s remaining';
    if (totalSeconds < 60) return '${totalSeconds}s remaining';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes < 60) {
      return seconds > 0
          ? '${minutes}m ${seconds}s remaining'
          : '${minutes}m remaining';
    }
    final hours = minutes ~/ 60;
    final remMinutes = minutes % 60;
    return remMinutes > 0
        ? '${hours}h ${remMinutes}m remaining'
        : '${hours}h remaining';
  }
}
