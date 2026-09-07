import 'package:uuid/uuid.dart';

import 'key_value_storage.dart';
import 'shared_preferences_storage.dart';

class DeviceIdentityService {
  static const String _deviceIdKey = 'device_id';

  final KeyValueStorage _storage;
  final Uuid _uuid;

  DeviceIdentityService({
    KeyValueStorage? storage,
    Uuid? uuid,
  })  : _storage = storage ?? SharedPreferencesStorage(),
        _uuid = uuid ?? const Uuid();

  Future<String> getDeviceId() async {
    final existingId = await _storage.getString(_deviceIdKey);

    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    final newId = _uuid.v4();

    await _storage.setString(
      _deviceIdKey,
      newId,
    );

    return newId;
  }
}