import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'protocol/protocol_encoder.dart';
import 'protocol/protocol_message.dart';
import 'protocol/protocol_stream_parser.dart';

class TcpConnection {
  final Socket socket;

  final ProtocolStreamParser _parser =
  ProtocolStreamParser();

  final StreamController<ProtocolMessage>
  _messagesController =
  StreamController<ProtocolMessage>.broadcast();

  Stream<ProtocolMessage> get messages =>
      _messagesController.stream;

  bool _closed = false;

  bool get isClosed => _closed;

  String get remoteAddress =>
      socket.remoteAddress.address;

  int get remotePort => socket.remotePort;

  TcpConnection(this.socket) {
    socket.listen(
      _handleData,
      onError: _handleError,
      onDone: _handleDone,
      cancelOnError: false,
    );
  }

  void _handleData(List<int> data) {
    if (_closed) {
      return;
    }

    try {
      final messages = _parser.addData(
        Uint8List.fromList(data),
      );

      for (final message in messages) {
        _messagesController.add(message);
      }
    } catch (error, stackTrace) {
      _messagesController.addError(
        error,
        stackTrace,
      );
    }
  }

  void _handleError(
      Object error,
      StackTrace stackTrace,
      ) {
    if (_closed) {
      return;
    }

    _messagesController.addError(
      error,
      stackTrace,
    );
  }

  void _handleDone() {
    _closeInternal();
  }

  Future<void> sendMessage(
      ProtocolMessage message,
      ) async {
    if (_closed) {
      throw StateError(
        'Connection is closed.',
      );
    }

    final data = ProtocolEncoder.encode(
      message,
    );

    socket.add(data);

    await socket.flush();
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }

    _closed = true;

    await socket.flush();
    await socket.close();

    await _messagesController.close();
  }

  void _closeInternal() {
    if (_closed) {
      return;
    }

    _closed = true;
    _messagesController.close();
  }
}
