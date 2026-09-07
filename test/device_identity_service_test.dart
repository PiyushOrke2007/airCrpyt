import 'package:flutter_test/flutter_test.dart';
import 'package:aircrypt/core/services/device_identity_service.dart';
import 'package:aircrypt/core/services/key_value_storage.dart';

class FakeKeyValueStorage implements KeyValueStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> getString(String key) async {
    return _data[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }
}

void main() {
  group('DeviceIdentityService', () {
    test('generates a device ID when none exists', () async {
      final storage = FakeKeyValueStorage();

      final service = DeviceIdentityService(
        storage: storage,
      );

      final id = await service.getDeviceId();

      expect(id, isNotEmpty);
      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-fA-F]{8}-'
            r'[0-9a-fA-F]{4}-'
            r'[0-9a-fA-F]{4}-'
            r'[0-9a-fA-F]{4}-'
            r'[0-9a-fA-F]{12}$',
          ),
        ),
      );
    });

    test('returns the same device ID on subsequent calls', () async {
      final storage = FakeKeyValueStorage();

      final service = DeviceIdentityService(
        storage: storage,
      );

      final firstId = await service.getDeviceId();
      final secondId = await service.getDeviceId();

      expect(secondId, equals(firstId));
    });

    test('stores the generated device ID', () async {
      final storage = FakeKeyValueStorage();

      final service = DeviceIdentityService(
        storage: storage,
      );

      final id = await service.getDeviceId();

      final storedId = await storage.getString('device_id');

      expect(storedId, equals(id));
    });
  });
}