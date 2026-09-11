import 'package:flutter/material.dart';
import 'features/settings/settings_screen.dart';

import 'features/files/received_files_screen.dart';
import 'features/history/transfer_history_screen.dart';
import 'features/trash/trash_screen.dart';

void main() {
  runApp(const AircryptApp());
}

class AircryptApp extends StatelessWidget {
  const AircryptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aircrypt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
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
        title: const Text('Aircrypt'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              const SizedBox(height: 24),
              const Icon(
                Icons.wifi_lock,
                size: 80,
              ),

              const Text(
                'Secure Offline Sharing',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Transfer files directly between nearby devices.',
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              FilledButton.icon(
                onPressed: () {
                  // Sending functionality will be added later.
                },
                icon: const Icon(Icons.upload),
                label: const Text('Send Files'),
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () {
                  // Receiving functionality will be added later.
                },
                icon: const Icon(Icons.download),
                label: const Text('Receive Files'),
              ),

              const Spacer(),

              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('Received Files'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const ReceivedFilesScreen(),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Transfer History'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const TransferHistoryScreen(),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Trash'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TrashScreen(),
                    ),
                  );
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}