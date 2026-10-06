import 'package:flutter/material.dart';

import '../../core/services/device_identity_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/aircrypt_theme.dart';
import '../../core/widgets/cyber_widgets.dart';
import '../transfer/tcp_receiver_screen.dart';
import '../transfer/tcp_sender_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final TextEditingController _deviceNameController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceName();
  }

  Future<void> _loadDeviceName() async {
    final savedName = await _settingsService.getDeviceName();

    _deviceNameController.text = savedName ?? 'My AirCrypt Node';

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDeviceName() async {
    final name = _deviceNameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device name cannot be empty.'),
        ),
      );
      return;
    }

    await _settingsService.saveDeviceName(name);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device identity updated successfully.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AirCryptColors.accentCyan),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('NODE CONFIGURATION'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CyberCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DEVICE NODE IDENTITY',
                      style: TextStyle(
                        color: AirCryptColors.accentCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'This device identifier will be broadcast to nearby AirCrypt peers on local Wi-Fi subnet.',
                      style: TextStyle(
                        color: AirCryptColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _deviceNameController,
                      style: const TextStyle(color: AirCryptColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Broadcasting Device Name',
                        prefixIcon: Icon(Icons.badge_outlined, color: AirCryptColors.accentCyan),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CyberButton(
                      label: 'SAVE IDENTIFIER',
                      icon: Icons.save_outlined,
                      width: double.infinity,
                      onPressed: _saveDeviceName,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'DIAGNOSTICS & DEBUG',
                style: TextStyle(
                  color: AirCryptColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),

              CyberCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.fingerprint, color: AirCryptColors.accentCyan),
                      title: const Text('Show Cryptographic Device ID'),
                      trailing: const Icon(Icons.chevron_right, color: AirCryptColors.accentCyan),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DeviceIdDebugScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.input, color: AirCryptColors.accentCyan),
                      title: const Text('TCP Receiver Protocol Test'),
                      trailing: const Icon(Icons.chevron_right, color: AirCryptColors.accentCyan),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TcpReceiverScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.output, color: AirCryptColors.accentCyan),
                      title: const Text('TCP Sender Protocol Test'),
                      trailing: const Icon(Icons.chevron_right, color: AirCryptColors.accentCyan),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TcpSenderScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeviceIdDebugScreen extends StatefulWidget {
  const DeviceIdDebugScreen({super.key});

  @override
  State<DeviceIdDebugScreen> createState() => _DeviceIdDebugScreenState();
}

class _DeviceIdDebugScreenState extends State<DeviceIdDebugScreen> {
  final DeviceIdentityService _identityService = DeviceIdentityService();

  String _deviceId = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    final id = await _identityService.getDeviceId();

    if (mounted) {
      setState(() {
        _deviceId = id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DEVICE IDENTITY GUID'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: CyberCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UNIQUE CRYPTOGRAPHIC NODE ID',
                  style: TextStyle(
                    color: AirCryptColors.accentCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                SelectableText(
                  _deviceId,
                  style: const TextStyle(
                    color: AirCryptColors.textPrimary,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
