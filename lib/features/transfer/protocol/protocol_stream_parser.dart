import 'dart:typed_data';

import 'protocol_decoder.dart';
import 'protocol_encoder.dart';
import 'protocol_message.dart';

class ProtocolStreamParser {
  final List<int> _buffer = [];

  List<ProtocolMessage> addData(
      Uint8List data,
      ) {
    _buffer.addAll(data);

    final messages = <ProtocolMessage>[];

    while (true) {
      if (_buffer.length <
          ProtocolDecoder.headerSize) {
        break;
      }

      final header = Uint8List.fromList(
        _buffer.sublist(
          0,
          ProtocolDecoder.headerSize,
        ),
      );

      final headerMessageLength =
      _getPayloadLength(header);

      final totalMessageLength =
          ProtocolDecoder.headerSize +
              headerMessageLength;

      if (_buffer.length <
          totalMessageLength) {
        break;
      }

      final messageBytes =
      Uint8List.fromList(
        _buffer.sublist(
          0,
          totalMessageLength,
        ),
      );

      _buffer.removeRange(
        0,
        totalMessageLength,
      );

      final message =
      ProtocolDecoder.decode(messageBytes);

      messages.add(message);
    }

    return messages;
  }

  int _getPayloadLength(
      Uint8List header,
      ) {
    final data = ByteData.sublistView(
      header,
    );

    return data.getUint32(
      8,
      Endian.big,
    );
  }

  int get bufferedBytes => _buffer.length;

  void clear() {
    _buffer.clear();
  }
}