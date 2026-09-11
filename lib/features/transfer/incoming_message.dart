import 'protocol/protocol_message.dart';
import 'tcp_connection.dart';

class IncomingMessage {
  final TcpConnection connection;
  final ProtocolMessage message;

  const IncomingMessage({
    required this.connection,
    required this.message,
  });
}
