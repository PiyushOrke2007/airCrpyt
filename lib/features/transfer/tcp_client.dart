import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'protocol/protocol_encoder.dart';
import 'protocol/protocol_message.dart';
import 'protocol/protocol_stream_parser.dart';

class TcpClient {
  Socket? _socket;

  final StreamController<ProtocolMessage>
  _messagesController =
  StreamController<ProtocolMessage>.broadcast();

  final ProtocolStreamParser _parser =
  ProtocolStreamParser();

  Stream<ProtocolMessage> get messages =>
      _messagesController.stream;

  bool get isConnected => _socket != null;

  Future<void> connect({
    required String host,
    required int port,
  }) async {
    if (isConnected) {
      throw StateError(
        'TCP client is already connected.',
      );
    }

    final socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 5),
    );

    _socket = socket;

    socket.listen(
      _handleData,
      onError: _handleError,
      onDone: _handleDone,
      cancelOnError: false,
    );
  }

  void _handleData(List<int> data) {
    final messages = _parser.addData(
      Uint8List.fromList(data),
    );

    for (final message in messages) {
      _messagesController.add(message);
    }
  }

  void _handleError(Object error) {
    _messagesController.addError(error);
  }

  void _handleDone() {
    _socket = null;
  }

  Future<void> sendMessage(
      ProtocolMessage message,
      ) async {
    final socket = _socket;

    if (socket == null) {
      throw StateError(
        'TCP client is not connected.',
      );
    }

    final data = ProtocolEncoder.encode(
      message,
    );

    socket.add(data);

    await socket.flush();
  }

  Future<void> disconnect() async {
    final socket = _socket;

    if (socket == null) {
      return;
    }

    _socket = null;

    await socket.flush();
    await socket.close();
  }

  Future<void> dispose() async {
    await disconnect();
    await _messagesController.close();
  }
}
