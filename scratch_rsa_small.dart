import 'package:aircrypt/core/security/rsa.dart';

void main() {
  final pair = generateRsa2048KeyPairImpl();
  final candidates = [BigInt.one, BigInt.from(2), BigInt.from(123456789), BigInt.from(65537), BigInt.from(1) << 1023];
  for (final m in candidates) {
    if (m >= pair.modulus) continue;
    final c = rsaPublicEncrypt(pair.publicKey, m);
    final d = rsaPrivateDecrypt(pair.privateKey, c);
    print('${m} == ${d}? ${m == d}');
  }
}
