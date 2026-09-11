import 'dart:async';
import 'dart:io';

import 'incoming_message.dart';
import 'tcp_connection.dart';

class TcpServer {
  ServerSocket? _serverSocket;

  final StreamController<IncomingMessage>
  _messagesController =
  StreamController<IncomingMessage>.broadcast();

  final List<TcpConnection> _connections = [];

  Stream<IncomingMessage> get messages =>
      _messagesController.stream;

  bool get isRunning =>
      _serverSocket != null;

  List<TcpConnection> get activeConnections =>
      List.unmodifiable(_connections);

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
      onError: (
          Object error,
          StackTrace stackTrace,
          ) {
        _messagesController.addError(
          error,
          stackTrace,
        );
      },
    );

    return _serverSocket!.port;
  }

  void _handleConnection(Socket socket) {
    final connection = TcpConnection(socket);

    _connections.add(connection);

    connection.messages.listen(
          (message) {
        if (!_messagesController.isClosed) {
          _messagesController.add(
            IncomingMessage(
              connection: connection,
              message: message,
            ),
          );
        }
      },
      onError: (
          Object error,
          StackTrace stackTrace,
          ) {
        if (!_messagesController.isClosed) {
          _messagesController.addError(
            error,
            stackTrace,
          );
        }
      },
      onDone: () {
        _connections.remove(connection);
      },
    );
  }

  Future<void> stop() async {
    final server = _serverSocket;

    if (server == null) {
      return;
    }

    _serverSocket = null;

    await server.close();

    final connections =
    List<TcpConnection>.from(_connections);

    for (final connection in connections) {
      await connection.close();
    }

    _connections.clear();
  }

  Future<void> dispose() async {
    await stop();

    await _messagesController.close();
  }
}
