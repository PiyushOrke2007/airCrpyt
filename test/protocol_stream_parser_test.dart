import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:aircrypt/features/transfer/protocol/message_type.dart';
import 'package:aircrypt/features/transfer/protocol/protocol_encoder.dart';
import 'package:aircrypt/features/transfer/protocol/protocol_message.dart';
import 'package:aircrypt/features/transfer/protocol/protocol_stream_parser.dart';

void main() {
  group('ProtocolStreamParser', () {
    test(
      'reconstructs a message split across multiple reads',
          () {
        final message =
        ProtocolMessage.text(
          type: MessageType.hello,
          text: 'Hello from Aircrypt',
        );

        final encoded =
        ProtocolEncoder.encode(message);

        final parser =
        ProtocolStreamParser();

        final firstPart =
        Uint8List.fromList(
          encoded.sublist(
            0,
            5,
          ),
        );

        final secondPart =
        Uint8List.fromList(
          encoded.sublist(
            5,
          ),
        );

        final firstMessages =
        parser.addData(firstPart);

        expect(firstMessages, isEmpty);

        final secondMessages =
        parser.addData(secondPart);

        expect(secondMessages.length, 1);

        expect(
          secondMessages.first.type,
          equals(MessageType.hello),
        );

        expect(
          secondMessages.first.textPayload,
          equals('Hello from Aircrypt'),
        );
      },
    );

    test(
      'can parse multiple messages received together',
          () {
        final message1 =
        ProtocolMessage.text(
          type: MessageType.hello,
          text: 'Hello',
        );

        final message2 =
        ProtocolMessage.text(
          type: MessageType.helloResponse,
          text: 'World',
        );

        final encoded1 =
        ProtocolEncoder.encode(message1);

        final encoded2 =
        ProtocolEncoder.encode(message2);

        final combined = Uint8List.fromList([
          ...encoded1,
          ...encoded2,
        ]);

        final parser =
        ProtocolStreamParser();

        final messages =
        parser.addData(combined);

        expect(messages.length, 2);

        expect(
          messages[0].type,
          equals(MessageType.hello),
        );

        expect(
          messages[0].textPayload,
          equals('Hello'),
        );

        expect(
          messages[1].type,
          equals(
            MessageType.helloResponse,
          ),
        );

        expect(
          messages[1].textPayload,
          equals('World'),
        );
      },
    );

    test(
      'keeps incomplete message buffered',
          () {
        final message =
        ProtocolMessage.text(
          type: MessageType.hello,
          text: 'Hello Aircrypt',
        );

        final encoded =
        ProtocolEncoder.encode(message);

        final parser =
        ProtocolStreamParser();

        final partial =
        Uint8List.fromList(
          encoded.sublist(
            0,
            encoded.length - 2,
          ),
        );

        final messages =
        parser.addData(partial);

        expect(messages, isEmpty);

        expect(
          parser.bufferedBytes,
          equals(partial.length),
        );
      },
    );
  });
}