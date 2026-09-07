import 'package:flutter_test/flutter_test.dart';
import 'package:aircrypt/core/models/device_info.dart';

void main() {
  test('DeviceInfo stores device information correctly', () {
    const device = DeviceInfo(
      deviceId: 'test-id',
      deviceName: 'Test Device',
      platform: 'android',
    );

    expect(device.deviceId, equals('test-id'));
    expect(device.deviceName, equals('Test Device'));
    expect(device.platform, equals('android'));
  });
}