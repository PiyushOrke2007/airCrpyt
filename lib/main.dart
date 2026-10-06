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
      theme: AirCryptTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AIRCRYPT TERMINAL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              
              // Central Visual Identity Branding
              const AirCryptHeader(),

              const SizedBox(height: 28),

              // P2P Status Badge
              Center(
                child: CyberBadge(
                  label: 'DISCOVERY ENGINE ACTIVE • P2P READY',
                  icon: Icons.cell_tower_outlined,
                  color: AirCryptColors.accentGreen,
                  isFilled: true,
                ),
              ),

              const SizedBox(height: 28),

              // Primary Actions
              CyberCard(
                showGlow: true,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CyberButton(
                      label: 'SECURE SEND FILES',
                      icon: Icons.upload_file_outlined,
                      width: double.infinity,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FileSelectionScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    CyberButton(
                      label: 'RECEIVE / NEARBY DEVICES',
                      icon: Icons.radar_outlined,
                      isPrimary: false,
                      width: double.infinity,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DeviceScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Navigation Quick Actions
              Text(
                'SYSTEM REPOSITORY',
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
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AirCryptColors.accentCyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.folder_special_outlined, size: 20),
                      ),
                      title: const Text('Received Vault', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('View and manage received encrypted files', style: TextStyle(fontSize: 12, color: AirCryptColors.textSecondary)),
                      trailing: const Icon(Icons.chevron_right, color: AirCryptColors.accentCyan),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReceivedFilesScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AirCryptColors.accentBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.history_toggle_off_outlined, size: 20, color: AirCryptColors.accentBlue),
                      ),
                      title: const Text('Transfer Audit Log', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('History of sent and received transfers', style: TextStyle(fontSize: 12, color: AirCryptColors.textSecondary)),
                      trailing: const Icon(Icons.chevron_right, color: AirCryptColors.accentCyan),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TransferHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AirCryptColors.accentRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_sweep_outlined, size: 20, color: AirCryptColors.accentRed),
                      ),
                      title: const Text('Secure Trash', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Recover or permanently purge deleted items', style: TextStyle(fontSize: 12, color: AirCryptColors.textSecondary)),
                      trailing: const Icon(Icons.chevron_right, color: AirCryptColors.accentCyan),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TrashScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Security Standard Specs Banner
              CyberCard(
                borderColor: AirCryptColors.accentCyan.withOpacity(0.15),
                backgroundColor: AirCryptColors.bgSurface.withOpacity(0.6),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.lock_clock_outlined, size: 22, color: AirCryptColors.accentCyan),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'CRYPTOGRAPHIC SPECIFICATION',
                            style: TextStyle(
                              color: AirCryptColors.accentCyan,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'AES-256-GCM • RSA-2048 • SHA-256 INTEGRITY',
                            style: TextStyle(
                              color: AirCryptColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
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
