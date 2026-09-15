import 'key_value_storage.dart';
import 'shared_preferences_storage.dart';

class SettingsService {
  static const String _deviceNameKey = 'device_name';

  final KeyValueStorage _keyValueStorage;

  SettingsService({
    KeyValueStorage? keyValueStorage,
  }) : _keyValueStorage =
      keyValueStorage ?? SharedPreferencesStorage();

  Future<String?> getDeviceName() async {
    return _keyValueStorage.getString(_deviceNameKey);
  }

  Future<void> saveDeviceName(String name) async {
    await _keyValueStorage.setString(
      _deviceNameKey,
      name,
    );
  }
}