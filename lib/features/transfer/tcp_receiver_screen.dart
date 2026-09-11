import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'incoming_message.dart';
import 'protocol/message_type.dart';
import 'protocol/protocol_message.dart';
import 'tcp_server.dart';

class TcpReceiverScreen extends StatefulWidget {
  const TcpReceiverScreen({super.key});

  @override
  State<TcpReceiverScreen> createState() =>
      _TcpReceiverScreenState();
}

class _TcpReceiverScreenState
    extends State<TcpReceiverScreen> {
  final TcpServer _server = TcpServer();

  StreamSubscription<IncomingMessage>?
  _messageSubscription;

  String _status = 'Starting...';
  String _lastMessage = 'No message received.';
  List<String> _ipAddresses = [];

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  Future<void> _startServer() async {
    try {
      // Start the TCP server.
      final port = await _server.start(
        port: 5000,
      );

      // Find IPv4 network interfaces.
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );

      // Store the addresses that we find.
      final addresses = <String>[];

      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          final value =
              '${interface.name}: ${address.address}';

          // Add the address to the list used by the UI.
          addresses.add(value);

          // Also print it to the debug console.
          debugPrint(value);
        }
      }

      // Update the UI.
      if (mounted) {
        setState(() {
          _ipAddresses = addresses;
          _status = 'Listening on port $port';
        });
      }

      // Listen for incoming Aircrypt protocol messages.
      _messageSubscription =
          _server.messages.listen(
                (IncomingMessage incoming) async {
              final message = incoming.message;

              if (!mounted) {
                return;
              }

              setState(() {
                _lastMessage =
                '${message.type.name}: '
                    '${message.textPayload}';
              });

              if (message.type == MessageType.hello) {
                await incoming.connection.sendMessage(
                  ProtocolMessage.text(
                    type: MessageType.helloResponse,
                    text: 'Aircrypt Hello Response',
                  ),
                );
              }
            },
            onError: (Object error) {
              if (!mounted) {
                return;
              }

              setState(() {
                _status = 'Server error: $error';
              });
            },
          );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Failed to start: $error';
      });
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _server.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TCP Receiver'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.wifi,
                size: 64,
              ),

              const SizedBox(height: 24),

              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Network addresses:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 8),

              if (_ipAddresses.isEmpty)
                const Text(
                  'No IPv4 network address found.',
                )
              else
                ..._ipAddresses.map(
                      (address) => Padding(
                    padding:
                    const EdgeInsets.only(
                      bottom: 8,
                    ),
                    child: SelectableText(address),
                  ),
                ),

              const SizedBox(height: 32),

              const Text(
                'Last message received:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 8),

              SelectableText(
                _lastMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
