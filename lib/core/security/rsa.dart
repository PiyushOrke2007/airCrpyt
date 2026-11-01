import 'dart:math';
import 'dart:typed_data';

import 'secure_random.dart';
import 'security_exceptions.dart';
import 'sha256.dart';

class RsaPublicKey {
  final BigInt modulus;
  final BigInt exponent;

  const RsaPublicKey({required this.modulus, required this.exponent});

  int get bitLength => modulus.bitLength;
}

class RsaPrivateKey {
  final BigInt modulus;
  final BigInt exponent;
  final BigInt p;
  final BigInt q;

  const RsaPrivateKey({
    required this.modulus,
    required this.exponent,
    required this.p,
    required this.q,
  });
}

class Rsa2048KeyPair {
  final RsaPublicKey publicKey;
  final RsaPrivateKey privateKey;

  const Rsa2048KeyPair({required this.publicKey, required this.privateKey});

  BigInt get modulus => publicKey.modulus;
}

BigInt _modPow(BigInt base, BigInt exponent, BigInt modulus) {
  if (modulus == BigInt.zero) {
    throw const SecurityException('modulus cannot be zero');
  }

  BigInt result = BigInt.one;
  BigInt baseMod = base % modulus;
  BigInt exp = exponent;

  while (exp > BigInt.zero) {
    if ((exp & BigInt.one) == BigInt.one) {
      result = (result * baseMod) % modulus;
    }
    baseMod = (baseMod * baseMod) % modulus;
    exp >>= 1;
  }

  return result;
}

BigInt _modInverse(BigInt value, BigInt modulus) {
  if (modulus == BigInt.one) {
    return BigInt.zero;
  }

  BigInt t = BigInt.zero;
  BigInt newT = BigInt.one;
  BigInt r = modulus;
  BigInt newR = value % modulus;

  while (newR != BigInt.zero) {
    final q = r ~/ newR;
    final tempT = newT;
    newT = (t - (q * newT)) % modulus;
    t = tempT;

    final tempR = newR;
    newR = r - (q * newR);
    r = tempR;
  }

  if (r != BigInt.one) {
    throw const SecurityException('RSA modulus is not invertible');
  }

  if (t < BigInt.zero) {
    return t + modulus;
  }

  return t;
}

bool _isProbablePrime(BigInt n, {int rounds = 40}) {
  if (n < BigInt.two) {
    return false;
  }
  if (n == BigInt.two || n == BigInt.from(3)) {
    return true;
  }
  if ((n & BigInt.one) == BigInt.zero) {
    return false;
  }

  BigInt d = n - BigInt.one;
  int s = 0;
  while ((d & BigInt.one) == BigInt.zero) {
    s++;
    d >>= 1;
  }

  final random = Random.secure();
  for (int i = 0; i < rounds; i++) {
    final range = n - BigInt.from(3);
    final a = BigInt.two + (BigInt.from(random.nextInt(1 << 30)) % range);
    var x = _modPow(a, d, n);

    if (x == BigInt.one || x == n - BigInt.one) {
      continue;
    }

    bool isComposite = true;
    for (int r = 1; r < s; r++) {
      x = _modPow(x, BigInt.two, n);
      if (x == n - BigInt.one) {
        isComposite = false;
        break;
      }
      if (x == BigInt.one) {
        return false;
      }
    }

    if (isComposite) {
      return false;
    }
  }

  return true;
}

BigInt _randomBigInt(int bits) {
  final random = Random.secure();
  final bytes = List<int>.filled((bits / 8).ceil(), 0, growable: false);

  for (int i = 0; i < bytes.length; i++) {
    bytes[i] = random.nextInt(256);
  }

  bytes[0] |= 0x80;
  bytes[bytes.length - 1] |= 0x01;

  BigInt result = BigInt.zero;
  for (final byte in bytes) {
    result = (result << 8) + BigInt.from(byte);
  }

  return result;
}

BigInt _generatePrime(int bits) {
  while (true) {
    final candidate = _randomBigInt(bits);
    if (_isProbablePrime(candidate, rounds: 20)) {
      return candidate;
    }
  }
}

Rsa2048KeyPair generateRsa2048KeyPairImpl() {
  final p = _generatePrime(1025);
  final q = _generatePrime(1025);
  final modulus = p * q;
  final phi = (p - BigInt.one) * (q - BigInt.one);
  const exponent = 65537;
  final privateExponent = _modInverse(BigInt.from(exponent), phi);

  return Rsa2048KeyPair(
    publicKey: RsaPublicKey(modulus: modulus, exponent: BigInt.from(exponent)),
    privateKey: RsaPrivateKey(
      modulus: modulus,
      exponent: privateExponent,
      p: p,
      q: q,
    ),
  );
}

BigInt rsaPublicEncrypt(RsaPublicKey publicKey, BigInt message) {
  return _modPow(message, publicKey.exponent, publicKey.modulus);
}

BigInt rsaPrivateDecrypt(RsaPrivateKey privateKey, BigInt ciphertext) {
  return _modPow(ciphertext, privateKey.exponent, privateKey.modulus);
}

List<int> bigIntToBytes(BigInt value, {required int length}) {
  final bytes = <int>[];
  BigInt temp = value;

  if (temp == BigInt.zero) {
    bytes.add(0);
  }

  while (temp > BigInt.zero) {
    bytes.add((temp & BigInt.from(0xFF)).toInt());
    temp >>= 8;
  }

  while (bytes.length < length) {
    bytes.add(0);
  }

  final padded = List<int>.filled(length, 0, growable: false);
  for (int i = 0; i < bytes.length && i < length; i++) {
    padded[length - 1 - i] = bytes[i];
  }

  return padded;
}

BigInt bytesToBigInt(List<int> bytes) {
  BigInt value = BigInt.zero;
  for (final byte in bytes) {
    value = (value << 8) + BigInt.from(byte & 0xFF);
  }
  return value;
}

Uint8List sha256OfBytes(List<int> data) =>
    Uint8List.fromList(Sha256Service.digest(data));
