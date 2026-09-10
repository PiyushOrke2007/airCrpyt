import 'dart:convert';

import 'message_type.dart';

class ProtocolMessage {
  final MessageType type;
  final List<int> payload;

  const ProtocolMessage({
    required this.type,
    required this.payload,
  });

  factory ProtocolMessage.text({
    required MessageType type,
    required String text,
  }) {
    return ProtocolMessage(
      type: type,
      payload: utf8.encode(text),
    );
  }

  String get textPayload {
    return utf8.decode(payload);
  }
}