import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _deviceNameKey = 'device_name';

  Future<String?> getDeviceName() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_deviceNameKey);
  }

  Future<void> saveDeviceName(String name) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_deviceNameKey, name);
  }
}