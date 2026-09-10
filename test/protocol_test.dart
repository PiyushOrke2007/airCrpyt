import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:aircrypt/features/transfer/protocol/message_type.dart';
import 'package:aircrypt/features/transfer/protocol/protocol_decoder.dart';
import 'package:aircrypt/features/transfer/protocol/protocol_encoder.dart';
import 'package:aircrypt/features/transfer/protocol/protocol_message.dart';

void main() {
  group('Aircrypt Protocol', () {
    test('encodes and decodes a text message', () {
      final original =
      ProtocolMessage.text(
        type: MessageType.hello,
        text: 'Hello from Aircrypt',
      );

      final encoded =
      ProtocolEncoder.encode(original);

      final decoded =
      ProtocolDecoder.decode(
        Uint8List.fromList(encoded),
      );

      expect(
        decoded.type,
        equals(MessageType.hello),
      );

      expect(
        decoded.textPayload,
        equals('Hello from Aircrypt'),
      );
    });

    test('rejects invalid magic', () {
      final data = Uint8List(12);

      expect(
            () => ProtocolDecoder.decode(data),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects incomplete message', () {
      final original =
      ProtocolMessage.text(
        type: MessageType.hello,
        text: 'Hello',
      );

      final encoded =
      ProtocolEncoder.encode(original);

      final incomplete =
      Uint8List.fromList(
        encoded.sublist(
          0,
          encoded.length - 1,
        ),
      );

      expect(
            () => ProtocolDecoder.decode(
          incomplete,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}