import 'dart:async';
import 'dart:convert';
import 'dart:io';

class TcpServer {
  ServerSocket? _serverSocket;

  final StreamController<String> _messagesController =
  StreamController<String>.broadcast();

  Stream<String> get messages =>
      _messagesController.stream;

  bool get isRunning => _serverSocket != null;

  Future<int> start({
    int port = 5000,
  }) async {
    if (isRunning) {
      throw StateError(
        'TCP server is already running.',
      );
    }

    _serverSocket = await ServerSocket.bind(
      InternetAddress.anyIPv4,
      port,
      shared: true,
    );

    _serverSocket!.listen(
      _handleConnection,
      onError: (Object error) {
        _messagesController.addError(error);
      },
    );

    return _serverSocket!.port;
  }

  Future<void> _handleConnection(
      Socket socket,
      ) async {
    try {
      await for (final data in socket) {
        final message = utf8.decode(
          data,
          allowMalformed: false,
        );

        _messagesController.add(message);
      }
    } catch (error, stackTrace) {
      _messagesController.addError(
        error,
        stackTrace,
      );
    } finally {
      await socket.close();
    }
  }

  Future<void> stop() async {
    final socket = _serverSocket;

    if (socket == null) {
      return;
    }

    _serverSocket = null;

    await socket.close();
  }

  Future<void> dispose() async {
    await stop();
    await _messagesController.close();
  }
  
}