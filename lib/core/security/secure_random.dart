import 'dart:math';

class SecureRandom {
  const SecureRandom();

  static List<int> nextBytes(int length) {
    if (length < 0) {
      throw ArgumentError.value(length, 'length', 'must be non-negative');
    }

    final random = Random.secure();
    final bytes = List<int>.filled(length, 0, growable: false);

    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }

    return bytes;
  }
}
