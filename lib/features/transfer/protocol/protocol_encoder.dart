import 'dart:convert';
import 'dart:typed_data';

import 'message_type.dart';
import 'protocol_message.dart';

class ProtocolEncoder {
  static const int magic = 0x41495243; // "AIRC"
  static const int version = 1;

  static const int headerSize = 12;

  static Uint8List encode(
      ProtocolMessage message,
      ) {
    final payload = Uint8List.fromList(
      message.payload,
    );

    final buffer = ByteData(headerSize + payload.length);

    buffer.setUint32(
      0,
      magic,
      Endian.big,
    );

    buffer.setUint8(
      4,
      version,
    );

    buffer.setUint8(
      5,
      message.type.index,
    );

    buffer.setUint16(
      6,
      0,
      Endian.big,
    );

    buffer.setUint32(
      8,
      payload.length,
      Endian.big,
    );

    final result = Uint8List(
      headerSize + payload.length,
    );

    result.setRange(
      0,
      headerSize,
      buffer.buffer.asUint8List(),
    );

    result.setRange(
      headerSize,
      result.length,
      payload,
    );

    return result;
  }
}