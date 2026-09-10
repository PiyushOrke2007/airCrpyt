import 'dart:io';

class TcpClient {
  Socket? _socket;

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

    _socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 5),
    );
  }

  Future<void> sendMessage(String message) async {
    final socket = _socket;

    if (socket == null) {
      throw StateError(
        'TCP client is not connected.',
      );
    }

    socket.write(message);
    await socket.flush();
  }

  Future<void> sendLine(String message) async {
    await sendMessage('$message\n');
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
}