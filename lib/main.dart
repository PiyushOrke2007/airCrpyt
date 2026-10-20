import 'package:flutter/material.dart';

import 'core/theme/aircrypt_theme.dart';
import 'core/widgets/cyber_widgets.dart';
import 'features/files/received_files_screen.dart';
import 'features/history/transfer_history_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/transfer/file_selection_screen.dart';
import 'features/transfer/finder/device_screen.dart';
import 'features/trash/trash_screen.dart';

void main() {
  runApp(const AircryptApp());
}

class AircryptApp extends StatelessWidget {
  const AircryptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AirCrypt',
      debugShowCheckedModeBanner: false,
      theme: AirCryptTheme.darkTheme('Amatic'),

      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AIRCRYPT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => _open(context, const SettingsScreen()),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FILE_LINK_v1.0',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  CyberBadge(
                    label: 'LOCAL NODE',
                    icon: Icons.circle,
                    color: AirCryptColors.textPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CyberCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _HomeAction(
                      eyebrow: 'BROADCAST',
                      title: 'SEND FILES',
                      icon: Icons.upload_outlined,
                      onTap: () => _open(context, const FileSelectionScreen()),
                    ),
                    const Divider(height: 1),
                    _HomeAction(
                      eyebrow: 'BEACON SCAN',
                      title: 'RECEIVE FILES',
                      icon: Icons.download_outlined,
                      onTap: () => _open(context, const DeviceScreen()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '[ SHORTCUTS ]',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'STORAGE & LOGS',
                    style: TextStyle(
                      color: AirCryptColors.textMuted,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CyberCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _HomeShortcut(
                      icon: Icons.folder_outlined,
                      title: 'RECEIVED FILES',
                      subtitle: 'Open your local vault',
                      onTap: () => _open(context, const ReceivedFilesScreen()),
                    ),
                    const Divider(height: 1),
                    _HomeShortcut(
                      icon: Icons.history,
                      title: 'TRANSFER HISTORY',
                      subtitle: 'View session log',
                      onTap: () =>
                          _open(context, const TransferHistoryScreen()),
                    ),
                    const Divider(height: 1),
                    _HomeShortcut(
                      icon: Icons.delete_outline,
                      title: 'TRASH',
                      subtitle: 'Recently deleted items',
                      onTap: () => _open(context, const TrashScreen()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CyberCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: AirCryptColors.accentCyan,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: const Text(
                        'LOCAL PEER-TO-PEER  /  ENCRYPTED TRANSFER',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

class _HomeAction extends StatelessWidget {
  final String eyebrow;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeAction({
    required this.eyebrow,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressInvert(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: const TextStyle(
                      color: AirCryptColors.textMuted,
                      fontSize: 14,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const Text('→', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}

class _HomeShortcut extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeShortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressInvert(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, size: 19, color: AirCryptColors.textPrimary),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 15,
            color: AirCryptColors.textSecondary,
          ),
        ),
        trailing: const Text('→', style: TextStyle(fontSize: 22)),
        dense: true,
      ),
    );
  }
}
