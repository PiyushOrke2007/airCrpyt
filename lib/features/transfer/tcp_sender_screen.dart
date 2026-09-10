import 'package:flutter/material.dart';

import 'tcp_client.dart';

class TcpSenderScreen extends StatefulWidget {
  const TcpSenderScreen({super.key});

  @override
  State<TcpSenderScreen> createState() =>
      _TcpSenderScreenState();
}

class _TcpSenderScreenState
    extends State<TcpSenderScreen> {
  final TcpClient _client = TcpClient();

  final TextEditingController _ipController =
  TextEditingController(
    text: '192.168.1.1',
  );

  String _status = 'Not connected';

  Future<void> _connect() async {
    final ip = _ipController.text.trim();

    if (ip.isEmpty) {
      setState(() {
        _status = 'Enter an IP address.';
      });
      return;
    }

    try {
      await _client.connect(
        host: ip,
        port: 5000,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Connected';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Connection failed: $error';
      });
    }
  }

  Future<void> _sendMessage() async {
    try {
      await _client.sendLine(
        'Hello from Aircrypt',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Message sent';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Send failed: $error';
      });
    }
  }

  Future<void> _disconnect() async {
    await _client.disconnect();

    if (!mounted) {
      return;
    }

    setState(() {
      _status = 'Disconnected';
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TCP Sender Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ipController,
              keyboardType:
              TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Receiver IP address',
                hintText: '192.168.1.100',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            FilledButton(
              onPressed:
              _client.isConnected ? null : _connect,
              child: const Text('Connect'),
            ),

            const SizedBox(height: 12),

            FilledButton(
              onPressed:
              _client.isConnected
                  ? _sendMessage
                  : null,
              child: const Text(
                'Send Hello Message',
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed:
              _client.isConnected
                  ? _disconnect
                  : null,
              child: const Text('Disconnect'),
            ),

            const SizedBox(height: 32),

            Text(
              'Status: $_status',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}