import 'package:flutter_test/flutter_test.dart';
import 'package:aircrypt/features/transfer/manager/transfer_session.dart';

void main() {
  test('TransferSession identifies transfers exceeding 30 minutes', () {
    final session = TransferSession(
      transferId: 'session_001',
      deviceId: 'device_001',
      deviceName: 'Device A',
      fileCount: 1,
      totalBytes: 10 * 1024 * 1024 * 1024, // 10 GB
    );

    expect(session.isExceedingTimeLimit, isFalse);

    // Simulate 100 KB/s transfer speed for 10 GB (takes ~27 hours)
    session.updateProgress(
      newBytesTransferred: 500 * 1024,
      newProgress: 0.0001,
    );
    session.bytesPerSecond = 100 * 1024; // 100 KB/s

    expect(session.estimatedSecondsRemaining, greaterThan(1800));
    expect(session.isExceedingTimeLimit, isTrue);
    expect(session.etaText, contains('remaining'));
  });

  test('TransferSession does not cancel transfers within 30 minutes', () {
    final session = TransferSession(
      transferId: 'session_002',
      deviceId: 'device_002',
      deviceName: 'Device B',
      fileCount: 1,
      totalBytes: 50 * 1024 * 1024, // 50 MB
    );

    // Simulate 5 MB/s transfer speed (takes 10 seconds)
    session.updateProgress(
      newBytesTransferred: 5 * 1024 * 1024,
      newProgress: 0.1,
    );
    session.bytesPerSecond = 5 * 1024 * 1024; // 5 MB/s

    expect(session.estimatedSecondsRemaining, lessThan(1800));
    expect(session.isExceedingTimeLimit, isFalse);
  });
}
