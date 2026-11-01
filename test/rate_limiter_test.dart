import 'package:flutter_test/flutter_test.dart';
import 'package:aircrypt/features/transfer/manager/transfer_session.dart';

void main() {
  test('TransferSession identifies transfers exceeding 1 minute', () {
    final session = TransferSession(
      transferId: 'session_001',
      deviceId: 'device_001',
      deviceName: 'Device A',
      fileCount: 1,
      totalBytes: 500 * 1024 * 1024, // 500 MB
    );

    expect(session.isExceedingTimeLimit, isFalse);

    // Simulate 1 MB/s transfer speed for 500 MB (takes ~500 seconds > 60s)
    session.updateProgress(
      newBytesTransferred: 10 * 1024 * 1024,
      newProgress: 0.02,
    );
    session.bytesPerSecond = 1 * 1024 * 1024; // 1 MB/s

    expect(session.estimatedSecondsRemaining, greaterThan(60));
    expect(session.isExceedingTimeLimit, isTrue);
    expect(session.etaText, contains('remaining'));
  });

  test('TransferSession does not cancel transfers within 1 minute', () {
    final session = TransferSession(
      transferId: 'session_002',
      deviceId: 'device_002',
      deviceName: 'Device B',
      fileCount: 1,
      totalBytes: 50 * 1024 * 1024, // 50 MB
    );

    // Simulate 5 MB/s transfer speed (takes 10 seconds < 60s)
    session.updateProgress(
      newBytesTransferred: 5 * 1024 * 1024,
      newProgress: 0.1,
    );
    session.bytesPerSecond = 5 * 1024 * 1024; // 5 MB/s

    expect(session.estimatedSecondsRemaining, lessThan(60));
    expect(session.isExceedingTimeLimit, isFalse);
  });
}
