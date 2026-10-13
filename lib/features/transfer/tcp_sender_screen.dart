import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/aircrypt_theme.dart';
import '../../core/widgets/cyber_widgets.dart';
import 'protocol/message_type.dart';
import 'protocol/protocol_message.dart';
import 'tcp_client.dart';

class TcpSenderScreen extends StatefulWidget {
  const TcpSenderScreen({super.key});

  @override
  State<TcpSenderScreen> createState() => _TcpSenderScreenState();
}

class _TcpSenderScreenState extends State<TcpSenderScreen> {
  final TcpClient _client = TcpClient();

  StreamSubscription<ProtocolMessage>? _messageSubscription;

  final TextEditingController _ipController = TextEditingController(
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
      await _client.connect(host: ip, port: 5000);

      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Connected';
      });

      _messageSubscription = _client.messages.listen((message) {
        if (!mounted) {
          return;
        }

        setState(() {
          _status =
              '${message.type.name}: '
              '${message.textPayload}';
        });
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
      await _client.sendMessage(
        ProtocolMessage.text(
          type: MessageType.hello,
          text: 'Hello from Aircrypt',
        ),
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
    _messageSubscription?.cancel();
    _ipController.dispose();
    _client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AIRCRYPT // TX DEBUG')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageIntro(
                title: 'Test a direct connection',
                subtitle: 'Connect to a receiver and send a small protocol test message.',
                icon: Icons.outbox_outlined,
              ),
              CyberCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _ipController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Receiver IP address',
                        hintText: '192.168.1.100',
                        prefixIcon: Icon(Icons.language_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _client.isConnected ? null : _connect,
                        child: const Text('Connect'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _client.isConnected ? _sendMessage : null,
                        child: const Text('Send test message'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _client.isConnected ? _disconnect : null,
                        child: const Text('Disconnect'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CyberCard(
                child: Row(
                  children: [
                    Icon(
                      _client.isConnected
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      color: _client.isConnected
                          ? AirCryptColors.accentGreen
                          : AirCryptColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connection status',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _status,
                            style: const TextStyle(
                              color: AirCryptColors.textSecondary,
                              fontSize: 13,
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
