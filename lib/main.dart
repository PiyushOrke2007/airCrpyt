import 'package:flutter/material.dart';

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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              const Icon(
                Icons.wifi_lock,
                size: 80,
              ),

              const SizedBox(height: 24),

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

              const SizedBox(height: 40),

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

              const Text(
                'Offline • Private • Direct',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}