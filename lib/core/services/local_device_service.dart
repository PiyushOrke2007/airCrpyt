import 'dart:io';

import '../models/device_info.dart';
import 'device_identity_service.dart';
import 'settings_service.dart';

class LocalDeviceService {
  final DeviceIdentityService _identityService;
  final SettingsService _settingsService;

  LocalDeviceService({
    DeviceIdentityService? identityService,
    SettingsService? settingsService,
  })  : _identityService = identityService ?? DeviceIdentityService(),
        _settingsService = settingsService ?? SettingsService();

  Future<DeviceInfo> getLocalDevice() async {
    final deviceId = await _identityService.getDeviceId();

    final savedName = await _settingsService.getDeviceName();

    final deviceName =
        savedName ?? 'My Aircrypt Device';

    return DeviceInfo(
      deviceId: deviceId,
      deviceName: deviceName,
      platform: Platform.operatingSystem,
    );
  }
}