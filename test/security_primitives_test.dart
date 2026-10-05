import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:aircrypt/core/security/aes_gcm.dart';
import 'package:aircrypt/core/security/key_generation.dart';
import 'package:aircrypt/core/security/rsa_oaep.dart';
import 'package:aircrypt/core/security/sha256.dart';

void main() {
  group('SHA-256', () {
    test('matches known digest for ASCII input', () {
      final digest = Sha256Service.digest(utf8Encode('abc'));
      expect(
        digest,
        equals([
          0xBA,
          0x78,
          0x16,
          0xBF,
          0x8F,
          0x01,
          0xCF,
          0xEA,
          0x41,
          0x41,
          0x40,
          0xDE,
          0x5D,
          0xAE,
          0x22,
          0x23,
          0xB0,
          0x03,
          0x61,
          0xA3,
          0x96,
          0x17,
          0x7A,
          0x9C,
          0xB4,
          0x10,
          0xFF,
          0x61,
          0xF2,
          0x00,
          0x15,
          0xAD,
        ]),
      );
    });

    test('supports empty and binary input', () {
      expect(
        Sha256Service.digest([]),
        equals([
          0xE3,
          0xB0,
          0xC4,
          0x42,
          0x98,
          0xFC,
          0x1C,
          0x14,
          0x9A,
          0xFB,
          0xF4,
          0xC8,
          0x99,
          0x6F,
          0xB9,
          0x24,
          0x27,
          0xAE,
          0x41,
          0xE4,
          0x64,
          0x9B,
          0x93,
          0x4C,
          0xA4,
          0x95,
          0x99,
          0x1B,
          0x78,
          0x52,
          0xB8,
          0x55,
        ]),
      );
      expect(Sha256Service.digest([0x00, 0xFF, 0x10, 0x7F]).length, equals(32));
    });
  });

  group('AES-256-GCM', () {
    test('encrypts and decrypts with authenticated data', () {
      final key = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final nonce = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
      final aad = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
      final plaintext = Uint8List.fromList(
        'hello secure transmission'.codeUnits,
      );

      final encrypted = Aes256GcmService.encrypt(
        key: key,
        nonce: nonce,
        plaintext: plaintext,
        aad: aad,
      );

      expect(encrypted.tag.length, equals(16));
      expect(encrypted.ciphertext.isNotEmpty, isTrue);

      final decrypted = Aes256GcmService.decrypt(
        key: key,
        nonce: nonce,
        ciphertext: encrypted.ciphertext,
        tag: encrypted.tag,
        aad: aad,
      );

      expect(decrypted, equals(plaintext));
    });

    test('rejects tampered ciphertext', () {
      final key = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final nonce = Uint8List.fromList(List<int>.filled(12, 7));
      final aad = Uint8List.fromList([0xA5, 0x5A]);
      final plaintext = Uint8List.fromList('tamper me'.codeUnits);

      final encrypted = Aes256GcmService.encrypt(
        key: key,
        nonce: nonce,
        plaintext: plaintext,
        aad: aad,
      );

      final tampered = Uint8List.fromList(encrypted.ciphertext);
      tampered[0] ^= 0xFF;

      expect(
        () => Aes256GcmService.decrypt(
          key: key,
          nonce: nonce,
          ciphertext: tampered,
          tag: encrypted.tag,
          aad: aad,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('RSA-OAEP-SHA256', () {
    test('generates a 2048-bit key pair and round-trips the AES key', () {
      final pair = KeyGeneration.generateRsa2048KeyPair();
      expect(pair.modulus.bitLength, greaterThanOrEqualTo(2048));

      final aesKey = List<int>.generate(32, (i) => i + 1);
      final encrypted = RsaOaepSha256.encrypt(
        publicKey: pair.publicKey,
        plaintext: aesKey,
      );
      final decrypted = RsaOaepSha256.decrypt(
        privateKey: pair.privateKey,
        ciphertext: encrypted,
      );

      expect(decrypted, equals(aesKey));
    });

    test('rejects invalid ciphertext length', () {
      final pair = KeyGeneration.generateRsa2048KeyPair();
      expect(
        () => RsaOaepSha256.decrypt(
          privateKey: pair.privateKey,
          ciphertext: Uint8List.fromList(List<int>.filled(10, 0xFF)),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}

List<int> utf8Encode(String value) => Uint8List.fromList(value.codeUnits);
