import 'dart:async';

import '../protocol/message_type.dart';
import '../protocol/protocol_message.dart';
import '../tcp_client.dart';
import 'connection_state.dart';

class ConnectionManager {
  final TcpClient _client;

  final StreamController<ProtocolMessage>
  _messageController =
  StreamController<ProtocolMessage>.broadcast();

  ConnectionState _state =
      ConnectionState.disconnected;

  StreamSubscription<ProtocolMessage>?
  _clientSubscription;

  Stream<ProtocolMessage> get messages =>
      _messageController.stream;

  ConnectionState get state => _state;

  ConnectionManager({
    TcpClient? client,
  }) : _client = client ?? TcpClient();

  Future<void> connect({
    required String host,
    required int port,
  }) async {
    if (_state != ConnectionState.disconnected) {
      throw StateError(
        'Connection is already active.',
      );
    }

    _state = ConnectionState.connecting;

    try {
      await _client.connect(
        host: host,
        port: port,
      );

      _clientSubscription =
          _client.messages.listen(
                (message) {
              _messageController.add(message);
            },
            onError: (Object error, StackTrace stackTrace) {
              _messageController.addError(
                error,
                stackTrace,
              );
            },
          );

      _state = ConnectionState.connected;

      await sendMessage(
        ProtocolMessage.text(
          type: MessageType.hello,
          text: 'Aircrypt Hello',
        ),
      );
    } catch (error) {
      _state = ConnectionState.failed;
      rethrow;
    }
  }

  Future<void> sendMessage(
      ProtocolMessage message,
      ) async {
    if (_state != ConnectionState.connected) {
      throw StateError(
        'Not connected.',
      );
    }

    await _client.sendMessage(message);
  }

  Future<void> disconnect() async {
    if (_state == ConnectionState.disconnected) {
      return;
    }

    _state = ConnectionState.closing;

    await _clientSubscription?.cancel();
    _clientSubscription = null;

    await _client.disconnect();

    _state = ConnectionState.disconnected;
  }

  Future<void> dispose() async {
    await disconnect();
    await _client.dispose();
    await _messageController.close();
  }
}
