import 'dart:typed_data';

class Sha256Service {
  const Sha256Service();

  static List<int> digest(List<int> data) {
    final message = List<int>.from(data, growable: true);
    final bitLength = data.length * 8;

    message.add(0x80);
    while ((message.length % 64) != 56) {
      message.add(0x00);
    }

    final lengthBytes = <int>[];
    for (int shift = 56; shift >= 0; shift -= 8) {
      lengthBytes.add((bitLength >> shift) & 0xFF);
    }
    message.addAll(lengthBytes);

    var h0 = 0x6A09E667;
    var h1 = 0xBB67AE85;
    var h2 = 0x3C6EF372;
    var h3 = 0xA54FF53A;
    var h4 = 0x510E527F;
    var h5 = 0x9B05688C;
    var h6 = 0x1F83D9AB;
    var h7 = 0x5BE0CD19;

    final words = List<int>.filled(64, 0, growable: false);
    for (int offset = 0; offset < message.length; offset += 64) {
      for (int i = 0; i < 16; i++) {
        final idx = offset + i * 4;
        words[i] =
            ((message[idx] << 24) & 0xFFFFFFFF) |
            ((message[idx + 1] << 16) & 0xFFFFFFFF) |
            ((message[idx + 2] << 8) & 0xFFFFFFFF) |
            (message[idx + 3] & 0xFFFFFFFF);
      }

      for (int i = 16; i < 64; i++) {
        final s0 =
            _rotr32(words[i - 15], 7) ^
            _rotr32(words[i - 15], 18) ^
            (words[i - 15] >> 3);
        final s1 =
            _rotr32(words[i - 2], 17) ^
            _rotr32(words[i - 2], 19) ^
            (words[i - 2] >> 10);
        words[i] = (words[i - 16] + s0 + words[i - 7] + s1) & 0xFFFFFFFF;
      }

      var a = h0;
      var b = h1;
      var c = h2;
      var d = h3;
      var e = h4;
      var f = h5;
      var g = h6;
      var h = h7;

      for (int i = 0; i < 64; i++) {
        final s1 = _rotr32(e, 6) ^ _rotr32(e, 11) ^ _rotr32(e, 25);
        final ch = ((e & f) ^ ((~e) & g)) & 0xFFFFFFFF;
        final temp1 = (h + s1 + ch + _k[i] + words[i]) & 0xFFFFFFFF;
        final s0 = _rotr32(a, 2) ^ _rotr32(a, 13) ^ _rotr32(a, 22);
        final maj = ((a & b) ^ (a & c) ^ (b & c)) & 0xFFFFFFFF;
        final temp2 = (s0 + maj) & 0xFFFFFFFF;

        h = g;
        g = f;
        f = e;
        e = (d + temp1) & 0xFFFFFFFF;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & 0xFFFFFFFF;
      }

      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
      h5 = (h5 + f) & 0xFFFFFFFF;
      h6 = (h6 + g) & 0xFFFFFFFF;
      h7 = (h7 + h) & 0xFFFFFFFF;
    }

    final out = Uint8List(32);
    final values = [h0, h1, h2, h3, h4, h5, h6, h7];
    for (int i = 0; i < values.length; i++) {
      final value = values[i];
      out[i * 4] = (value >> 24) & 0xFF;
      out[i * 4 + 1] = (value >> 16) & 0xFF;
      out[i * 4 + 2] = (value >> 8) & 0xFF;
      out[i * 4 + 3] = value & 0xFF;
    }

    return out;
  }

  static int _rotr32(int value, int bits) {
    return ((value >>> bits) | ((value << (32 - bits)) & 0xFFFFFFFF)) &
        0xFFFFFFFF;
  }

  static const List<int> _k = [
    0x428A2F98,
    0x71374491,
    0xB5C0FBCF,
    0xE9B5DBA5,
    0x3956C25B,
    0x59F111F1,
    0x923F82A4,
    0xAB1C5ED5,
    0xD807AA98,
    0x12835B01,
    0x243185BE,
    0x550C7DC3,
    0x72BE5D74,
    0x80DEB1FE,
    0x9BDC06A7,
    0xC19BF174,
    0xE49B69C1,
    0xEFBE4786,
    0x0FC19DC6,
    0x240CA1CC,
    0x2DE92C6F,
    0x4A7484AA,
    0x5CB0A9DC,
    0x76F988DA,
    0x983E5152,
    0xA831C66D,
    0xB00327C8,
    0xBF597FC7,
    0xC6E00BF3,
    0xD5A79147,
    0x06CA6351,
    0x14292967,
    0x27B70A85,
    0x2E1B2138,
    0x4D2C6DFC,
    0x53380D13,
    0x650A7354,
    0x766A0ABB,
    0x81C2C92E,
    0x92722C85,
    0xA2BFE8A1,
    0xA81A664B,
    0xC24B8B70,
    0xC76C51A3,
    0xD192E819,
    0xD6990624,
    0xF40E3585,
    0x106AA070,
    0x19A4C116,
    0x1E376C08,
    0x2748774C,
    0x34B0BCB5,
    0x391C0CB3,
    0x4ED8AA4A,
    0x5B9CCA4F,
    0x682E6FF3,
    0x748F82EE,
    0x78A5636F,
    0x84C87814,
    0x8CC70208,
    0x90BEFFFA,
    0xA4506CEB,
    0xBEF9A3F7,
    0xC67178F2,
  ];
}
