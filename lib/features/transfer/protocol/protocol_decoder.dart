import 'dart:typed_data';

import 'message_type.dart';
import 'protocol_message.dart';
import 'protocol_encoder.dart';

class ProtocolDecoder {
  static const int headerSize = 12;

  static ProtocolMessage decode(
      Uint8List data,
      ) {
    if (data.length < headerSize) {
      throw const FormatException(
        'Incomplete protocol header.',
      );
    }

    final header = ByteData.sublistView(
      data,
      0,
      headerSize,
    );

    final magic = header.getUint32(
      0,
      Endian.big,
    );

    if (magic != ProtocolEncoder.magic) {
      throw const FormatException(
        'Invalid Aircrypt message.',
      );
    }

    final version = header.getUint8(4);

    if (version != ProtocolEncoder.version) {
      throw FormatException(
        'Unsupported protocol version: $version',
      );
    }

    final messageTypeIndex =
    header.getUint8(5);

    if (messageTypeIndex >=
        MessageType.values.length) {
      throw const FormatException(
        'Unknown message type.',
      );
    }

    final payloadLength = header.getUint32(
      8,
      Endian.big,
    );

    if (data.length <
        headerSize + payloadLength) {
      throw const FormatException(
        'Incomplete protocol payload.',
      );
    }

    final payload = Uint8List.fromList(
      data.sublist(
        headerSize,
        headerSize + payloadLength,
      ),
    );

    return ProtocolMessage(
      type: MessageType.values[
      messageTypeIndex
      ],
      payload: payload,
    );
  }
}