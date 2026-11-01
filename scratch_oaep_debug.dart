import 'dart:typed_data';
import 'package:aircrypt/core/security/key_generation.dart';
import 'package:aircrypt/core/security/rsa.dart';
import 'package:aircrypt/core/security/rsa_oaep.dart';
import 'package:aircrypt/core/security/sha256.dart';

List<int> mgf1(List<int> seed, int length) {
  final result = <int>[];
  int counter = 0;
  while (result.length < length) {
    final block = <int>[...seed];
    block.addAll([
      (counter >> 24) & 0xFF,
      (counter >> 16) & 0xFF,
      (counter >> 8) & 0xFF,
      counter & 0xFF,
    ]);
    result.addAll(Sha256Service.digest(block));
    counter++;
  }
  return result.sublist(0, length);
}

List<int> xor(List<int> left, List<int> right) {
  final out = List<int>.filled(left.length, 0, growable: false);
  for (int i = 0; i < left.length; i++) {
    out[i] = left[i] ^ right[i];
  }
  return out;
}

void main() {
  final pair = KeyGeneration.generateRsa2048KeyPair();
  final aesKey = List<int>.generate(32, (i) => i + 1);
  final encrypted = RsaOaepSha256.encrypt(publicKey: pair.publicKey, plaintext: aesKey);
  final k = (pair.privateKey.modulus.bitLength + 7) ~/ 8;
  print('k=$k');
  print('cipher_len=${encrypted.length}');
  final value = bytesToBigInt(encrypted);
  final m = rsaPrivateDecrypt(pair.privateKey, value);
  final encoded = bigIntToBytes(m, length: k);
  print('encoded0=${encoded.first}');
  print('encoded prefix=${encoded.take(12).toList()}');

  final maskedSeed = encoded.sublist(1, 1 + 32);
  final maskedDb = encoded.sublist(1 + 32);
  final seedMask = mgf1(maskedDb, 32);
  final seed = xor(maskedSeed, seedMask);
  final dbMask = mgf1(seed, k - 33);
  final db = xor(maskedDb, dbMask);
  print('lhash=${Sha256Service.digest([]).sublist(0, 8)}');
  print('db first 40=${db.take(40).toList()}');
  print('db len=${db.length}');
  print('seed first 8=${seed.take(8).toList()}');
  print('db.indexOf(1)=${db.indexOf(0x01)}');
}
