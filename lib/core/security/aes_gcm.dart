import 'dart:typed_data';

import 'security_exceptions.dart';

class GcmEncryptedData {
  final Uint8List ciphertext;
  final Uint8List tag;

  const GcmEncryptedData({required this.ciphertext, required this.tag});
}

class Aes256GcmService {
  const Aes256GcmService();

  static GcmEncryptedData encrypt({
    required List<int> key,
    required List<int> nonce,
    required List<int> plaintext,
    required List<int> aad,
  }) {
    if (key.length != 32) {
      throw const InvalidKeyLengthException(
        'AES-256 keys must be 32 bytes long',
      );
    }
    if (nonce.length != 12) {
      throw const InvalidKeyLengthException('GCM nonce must be 12 bytes long');
    }

    final ciphertext = _ctrTransform(key, nonce, plaintext);
    final tag = _computeTag(
      key: key,
      nonce: nonce,
      aad: aad,
      ciphertext: ciphertext,
    );

    return GcmEncryptedData(
      ciphertext: Uint8List.fromList(ciphertext),
      tag: Uint8List.fromList(tag),
    );
  }

  static Uint8List decrypt({
    required List<int> key,
    required List<int> nonce,
    required List<int> ciphertext,
    required List<int> tag,
    required List<int> aad,
  }) {
    if (key.length != 32) {
      throw const InvalidKeyLengthException(
        'AES-256 keys must be 32 bytes long',
      );
    }
    if (nonce.length != 12) {
      throw const InvalidKeyLengthException('GCM nonce must be 12 bytes long');
    }

    final expectedTag = _computeTag(
      key: key,
      nonce: nonce,
      aad: aad,
      ciphertext: ciphertext,
    );
    if (!_constantTimeEquals(expectedTag, tag)) {
      throw const AuthenticationFailedException(
        'GCM authentication tag mismatch',
      );
    }

    return Uint8List.fromList(_ctrTransform(key, nonce, ciphertext));
  }

  static List<int> _computeTag({
    required List<int> key,
    required List<int> nonce,
    required List<int> aad,
    required List<int> ciphertext,
  }) {
    final h = _encryptBlock(
      Uint8List.fromList(List<int>.filled(16, 0, growable: false)),
      _expandKey(key),
    );
    final j0 = Uint8List(16);
    j0.setRange(0, nonce.length, nonce);
    j0[15] = 0x01;

    final ghash = _ghash(aad, ciphertext, h);
    final s = _encryptBlock(j0, _expandKey(key));
    final tag = _xorBytes(ghash, s);
    return tag.sublist(0, 16);
  }

  static Uint8List _ghash(List<int> aad, List<int> ciphertext, List<int> h) {
    final x = Uint8List(16);
    final blocks = <List<int>>[];

    if (aad.isNotEmpty) {
      blocks.addAll(_padBlocks(aad));
    }
    if (ciphertext.isNotEmpty) {
      blocks.addAll(_padBlocks(ciphertext));
    }

    final lengthBlock = ByteData(16);
    lengthBlock.setUint64(0, aad.length * 8, Endian.big);
    lengthBlock.setUint64(8, ciphertext.length * 8, Endian.big);
    blocks.add(lengthBlock.buffer.asUint8List());

    for (final block in blocks) {
      final combined = _xorBytes(x, block);
      x.setRange(0, 16, _gfMultiply(combined, h));
    }

    return x;
  }

  static List<List<int>> _padBlocks(List<int> data) {
    final result = <List<int>>[];
    for (int i = 0; i < data.length; i += 16) {
      final part = data.sublist(i, (i + 16).clamp(0, data.length));
      final padded = Uint8List(16);
      padded.setRange(0, part.length, part);
      result.add(padded);
    }
    return result;
  }

  static Uint8List _gfMultiply(List<int> x, List<int> h) {
    var z = Uint8List(16);
    var v = Uint8List.fromList(h);
    final bits = Uint8List.fromList(x);

    for (int bit = 0; bit < 128; bit++) {
      final currentByteIndex = bit ~/ 8;
      final bitMask = 1 << (7 - (bit % 8));
      if ((bits[currentByteIndex] & bitMask) != 0) {
        z = _xorBytes(z, v);
      }

      final msb = v[0] & 0x80;
      v = _shiftRight(v);
      if (msb != 0) {
        v[15] ^= 0xE1;
      }
    }

    return z;
  }

  static Uint8List _shiftRight(List<int> value) {
    final out = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      final current = value[i];
      final next = i + 1 < value.length ? value[i + 1] : 0;
      out[i] = ((current >> 1) & 0x7F) | ((next & 0x01) << 7);
    }
    return out;
  }

  static Uint8List _ctrTransform(List<int> key, List<int> nonce, List<int> data) {
    final expandedKey = _expandKey(key);
    final initialCounter = Uint8List(16);
    initialCounter.setRange(0, nonce.length, nonce);
    initialCounter[15] = 0x01;

    var counter = _incrementCounter(initialCounter);
    final output = <int>[];
    for (int offset = 0; offset < data.length; offset += 16) {
      final chunk = data.sublist(offset, (offset + 16).clamp(0, data.length));
      final keystream = _encryptBlock(counter, expandedKey);
      final cipherChunk = _xorBytes(Uint8List.fromList(chunk), keystream);
      output.addAll(cipherChunk.take(chunk.length));
      counter = _incrementCounter(counter);
    }
    return Uint8List.fromList(output);
  }

  static Uint8List _incrementCounter(List<int> counter) {
    final result = Uint8List.fromList(counter);
    final value =
        ((result[12] << 24) | (result[13] << 16) | (result[14] << 8) | result[15]) +
            1;
    result[12] = (value >> 24) & 0xFF;
    result[13] = (value >> 16) & 0xFF;
    result[14] = (value >> 8) & 0xFF;
    result[15] = value & 0xFF;
    return result;
  }

  static bool _constantTimeEquals(List<int> left, List<int> right) {
    if (left.length != right.length) {
      return false;
    }
    int diff = 0;
    for (int i = 0; i < left.length; i++) {
      diff |= left[i] ^ right[i];
    }
    return diff == 0;
  }

  static Uint8List _xorBytes(List<int> left, List<int> right) {
    final result = Uint8List(left.length);
    for (int i = 0; i < left.length; i++) {
      result[i] = left[i] ^ right[i % right.length];
    }
    return result;
  }

  static List<List<int>> _expandKey(List<int> key) {
    final words = List<int>.filled(60, 0, growable: false);
    for (int i = 0; i < 8; i++) {
      words[i] =
          ((key[i * 4] << 24) & 0xFFFFFFFF) |
          ((key[i * 4 + 1] << 16) & 0xFFFFFFFF) |
          ((key[i * 4 + 2] << 8) & 0xFFFFFFFF) |
          (key[i * 4 + 3] & 0xFFFFFFFF);
    }

    for (int i = 8; i < 60; i++) {
      var temp = words[i - 1];
      if (i % 8 == 0) {
        temp = _subWord(_rotWord(temp)) ^ _rcon(i ~/ 8);
      } else if (i % 8 == 4) {
        temp = _subWord(temp);
      }
      words[i] = words[i - 8] ^ temp;
    }

    final roundKeys = <List<int>>[];
    for (int i = 0; i < 15; i++) {
      final start = i * 4;
      final roundKey = <int>[];
      for (int j = start; j < start + 4; j++) {
        final value = words[j];
        roundKey.addAll([
          (value >> 24) & 0xFF,
          (value >> 16) & 0xFF,
          (value >> 8) & 0xFF,
          value & 0xFF,
        ]);
      }
      roundKeys.add(roundKey);
    }

    return roundKeys;
  }

  static int _rotWord(int word) {
    return (((word << 8) & 0xFFFFFFFF) | ((word >> 24) & 0xFF)) & 0xFFFFFFFF;
  }

  static int _subWord(int word) {
    final bytes = [
      (word >> 24) & 0xFF,
      (word >> 16) & 0xFF,
      (word >> 8) & 0xFF,
      word & 0xFF,
    ];
    final substituted = bytes.map((byte) => _sBox[byte]).toList();
    return ((substituted[0] << 24) & 0xFFFFFFFF) |
        ((substituted[1] << 16) & 0xFFFFFFFF) |
        ((substituted[2] << 8) & 0xFFFFFFFF) |
        (substituted[3] & 0xFFFFFFFF);
  }

  static int _rcon(int round) {
    const values = [0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36];
    return (values[round] << 24) & 0xFFFFFFFF;
  }

  static List<int> _encryptBlock(List<int> block, List<List<int>> roundKeys) {
    var state = List<int>.from(block);
    state = _addRoundKey(state, roundKeys[0]);

    for (int round = 1; round < 14; round++) {
      state = _subBytes(state);
      state = _shiftRows(state);
      state = _mixColumns(state);
      state = _addRoundKey(state, roundKeys[round]);
    }

    state = _subBytes(state);
    state = _shiftRows(state);
    state = _addRoundKey(state, roundKeys[14]);
    return state;
  }

  static List<int> _addRoundKey(List<int> state, List<int> key) {
    final result = List<int>.filled(16, 0, growable: false);
    for (int i = 0; i < 16; i++) {
      result[i] = state[i] ^ key[i];
    }
    return result;
  }

  static List<int> _subBytes(List<int> state) {
    final result = List<int>.filled(16, 0, growable: false);
    for (int i = 0; i < 16; i++) {
      result[i] = _sBox[state[i] & 0xFF];
    }
    return result;
  }

  static List<int> _shiftRows(List<int> state) {
    final result = List<int>.filled(16, 0, growable: false);
    result[0] = state[0];
    result[1] = state[5];
    result[2] = state[10];
    result[3] = state[15];
    result[4] = state[4];
    result[5] = state[9];
    result[6] = state[14];
    result[7] = state[3];
    result[8] = state[8];
    result[9] = state[13];
    result[10] = state[2];
    result[11] = state[7];
    result[12] = state[12];
    result[13] = state[1];
    result[14] = state[6];
    result[15] = state[11];
    return result;
  }

  static List<int> _mixColumns(List<int> state) {
    final result = List<int>.filled(16, 0, growable: false);
    for (int col = 0; col < 4; col++) {
      final base = col * 4;
      final s0 = state[base];
      final s1 = state[base + 1];
      final s2 = state[base + 2];
      final s3 = state[base + 3];
      result[base] = _mul2(s0) ^ _mul3(s1) ^ s2 ^ s3;
      result[base + 1] = s0 ^ _mul2(s1) ^ _mul3(s2) ^ s3;
      result[base + 2] = s0 ^ s1 ^ _mul2(s2) ^ _mul3(s3);
      result[base + 3] = _mul3(s0) ^ s1 ^ s2 ^ _mul2(s3);
    }
    return result;
  }

  static int _mul2(int value) => _xtime(value);
  static int _mul3(int value) => _xtime(value) ^ value;

  static int _xtime(int value) {
    final v = value & 0xFF;
    return ((v << 1) ^ ((v >> 7) * 0x1B)) & 0xFF;
  }

  static const List<int> _sBox = [
    0x63, 0x7C, 0x77, 0x7B, 0xF2, 0x6B, 0x6F, 0xC5, 0x30, 0x01, 0x67, 0x2B,
    0xFE, 0xD7, 0xAB, 0x76, 0xCA, 0x82, 0xC9, 0x7D, 0xFA, 0x59, 0x47, 0xF0,
    0xAD, 0xD4, 0xA2, 0xAF, 0x9C, 0xA4, 0x72, 0xC0, 0xB7, 0xFD, 0x93, 0x26,
    0x36, 0x3F, 0xF7, 0xCC, 0x34, 0xA5, 0xE5, 0xF1, 0x71, 0xD8, 0x31, 0x15,
    0x04, 0xC7, 0x23, 0xC3, 0x18, 0x96, 0x05, 0x9A, 0x07, 0x12, 0x80, 0xE2,
    0xEB, 0x27, 0xB2, 0x75, 0x09, 0x83, 0x2C, 0x1A, 0x1B, 0x6E, 0x5A, 0xA0,
    0x52, 0x3B, 0xD6, 0xB3, 0x29, 0xE3, 0x2F, 0x84, 0x53, 0xD1, 0x00, 0xED,
    0x20, 0xFC, 0xB1, 0x5B, 0x6A, 0xCB, 0xBE, 0x39, 0x4A, 0x4C, 0x58, 0xCF,
    0xD0, 0xEF, 0xAA, 0xFB, 0x43, 0x4D, 0x33, 0x85, 0x45, 0xF9, 0x02, 0x7F,
    0x50, 0x3C, 0x9F, 0xA8, 0x51, 0xA3, 0x40, 0x8F, 0x92, 0x9D, 0x38, 0xF5,
    0xBC, 0xB6, 0xDA, 0x21, 0x10, 0xFF, 0xF3, 0xD2, 0xCD, 0x0C, 0x13, 0xEC,
    0x5F, 0x97, 0x44, 0x17, 0xC4, 0xA7, 0x7E, 0x3D, 0x64, 0x5D, 0x19, 0x73,
    0x60, 0x81, 0x4F, 0xDC, 0x22, 0x2A, 0x90, 0x88, 0x46, 0xEE, 0xB8, 0x14,
    0xDE, 0x5E, 0x0B, 0xDB, 0xE0, 0x32, 0x3A, 0x0A, 0x49, 0x06, 0x24, 0x5C,
    0xC2, 0xD3, 0xAC, 0x62, 0x91, 0x95, 0xE4, 0x79, 0xE7, 0xC8, 0x37, 0x6D,
    0x8D, 0xD5, 0x4E, 0xA9, 0x6C, 0x56, 0xF4, 0xEA, 0x65, 0x7A, 0xAE, 0x08,
    0xBA, 0x78, 0x25, 0x2E, 0x1C, 0xA6, 0xB4, 0xC6, 0xE8, 0xDD, 0x74, 0x1F,
    0x4B, 0xBD, 0x8B, 0x8A, 0x70, 0x3E, 0xB5, 0x66, 0x48, 0x03, 0xF6, 0x0E,
    0x61, 0x35, 0x57, 0xB9, 0x86, 0xC1, 0x1D, 0x9E, 0xE1, 0xF8, 0x98, 0x11,
    0x69, 0xD9, 0x8E, 0x94, 0x9B, 0x1E, 0x87, 0xE9, 0xCE, 0x55, 0x28, 0xDF,
    0x8C, 0xA1, 0x89, 0x0D, 0xBF, 0xE6, 0x42, 0x68, 0x41, 0x99, 0x2D, 0x0F,
    0xB0, 0x54, 0xBB, 0x16,
  ];
}
