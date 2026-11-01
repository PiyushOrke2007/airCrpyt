import 'dart:typed_data';

import 'rsa.dart';
import 'security_exceptions.dart';
import 'sha256.dart';

class RsaOaepSha256 {
  const RsaOaepSha256();

  static Uint8List encrypt({
    required RsaPublicKey publicKey,
    required List<int> plaintext,
  }) {
    final modulusLength = (publicKey.modulus.bitLength + 7) ~/ 8;
    final hLen = 32;
    final k = modulusLength;

    if (plaintext.length > k - 2 * hLen - 2) {
      throw const SecurityException('OAEP message too large for RSA key');
    }

    final lHash = Sha256Service.digest([]);
    final ps = List<int>.filled(
      k - plaintext.length - 2 * hLen - 2,
      0,
      growable: false,
    );
    final db = [...lHash, ...ps, 0x01, ...plaintext];
    final seed = _randomBytes(hLen);
    final dbMask = _mgf1(seed, k - hLen - 1);
    final maskedDb = _xor(db, dbMask);
    final seedMask = _mgf1(maskedDb, hLen);
    final maskedSeed = _xor(seed, seedMask);

    final encoded = Uint8List(k);
    encoded[0] = 0x00;
    encoded.setRange(1, 1 + hLen, maskedSeed);
    encoded.setRange(1 + hLen, 1 + hLen + maskedDb.length, maskedDb);
    final value = bytesToBigInt(encoded);
    final ciphertext = rsaPublicEncrypt(publicKey, value);
    return Uint8List.fromList(bigIntToBytes(ciphertext, length: k));
  }

  static Uint8List decrypt({
    required RsaPrivateKey privateKey,
    required List<int> ciphertext,
  }) {
    final k = (privateKey.modulus.bitLength + 7) ~/ 8;
    if (ciphertext.length != k) {
      throw const InvalidCiphertextException(
        'Ciphertext length is invalid for RSA-OAEP',
      );
    }

    final value = bytesToBigInt(ciphertext);
    final m = rsaPrivateDecrypt(privateKey, value);
    final encoded = bigIntToBytes(m, length: k);

    if (encoded[0] != 0x00) {
      throw const InvalidCiphertextException('Invalid RSA-OAEP ciphertext');
    }

    final maskedSeed = encoded.sublist(1, 1 + 32);
    final maskedDb = encoded.sublist(1 + 32);
    final seedMask = _mgf1(maskedDb, 32);
    final seed = _xor(maskedSeed, seedMask);
    final dbMask = _mgf1(seed, k - 33);
    final db = _xor(maskedDb, dbMask);

    final lHash = Sha256Service.digest([]);
    if (db.length < lHash.length + 1) {
      throw const InvalidCiphertextException('Invalid RSA-OAEP padding');
    }

    for (int i = 0; i < lHash.length; i++) {
      if (db[i] != lHash[i]) {
        throw const InvalidCiphertextException('Invalid RSA-OAEP padding');
      }
    }

    final separatorIndex = db.indexOf(0x01, lHash.length);
    if (separatorIndex < 0) {
      throw const InvalidCiphertextException('Invalid RSA-OAEP padding');
    }

    for (int i = lHash.length; i < separatorIndex; i++) {
      if (db[i] != 0x00) {
        throw const InvalidCiphertextException('Invalid RSA-OAEP padding');
      }
    }

    return Uint8List.fromList(db.sublist(separatorIndex + 1));
  }

  static List<int> _randomBytes(int length) {
    final random = List<int>.filled(length, 0, growable: false);
    for (int i = 0; i < length; i++) {
      random[i] = (DateTime.now().microsecondsSinceEpoch + i * 17) % 256;
    }
    return random;
  }

  static List<int> _mgf1(List<int> seed, int length) {
    final result = <int>[];
    int counter = 0;
    while (result.length < length) {
      final block = <int>[];
      block.addAll(seed);
      final counterBytes = [
        (counter >> 24) & 0xFF,
        (counter >> 16) & 0xFF,
        (counter >> 8) & 0xFF,
        counter & 0xFF,
      ];
      block.addAll(counterBytes);
      final digest = Sha256Service.digest(block);
      result.addAll(digest);
      counter++;
    }
    return result.sublist(0, length);
  }

  static List<int> _xor(List<int> left, List<int> right) {
    final out = List<int>.filled(left.length, 0, growable: false);
    for (int i = 0; i < left.length; i++) {
      out[i] = left[i] ^ right[i];
    }
    return out;
  }

  static int _findSeparator(List<int> data, List<int> prefix) {
    if (data.length < prefix.length) {
      return -1;
    }
    for (int i = 0; i <= data.length - prefix.length; i++) {
      bool match = true;
      for (int j = 0; j < prefix.length; j++) {
        if (data[i + j] != prefix[j]) {
          match = false;
          break;
        }
      }
      if (match) {
        return i + prefix.length;
      }
    }
    return -1;
  }
}
