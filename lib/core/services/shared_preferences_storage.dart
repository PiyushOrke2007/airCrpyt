import 'package:shared_preferences/shared_preferences.dart';

import 'key_value_storage.dart';

class SharedPreferencesStorage implements KeyValueStorage {
  @override
  Future<String?> getString(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(key, value);
  }
}