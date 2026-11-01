import 'package:aircrypt/core/security/rsa.dart';
void main() {
  final pair = generateRsa2048KeyPairImpl();
  final e = pair.publicKey.exponent;
  final d = pair.privateKey.exponent;
  final phi = (pair.privateKey.p - BigInt.one) * (pair.privateKey.q - BigInt.one);
  print('ed mod phi = ${(e*d) % phi}');
  print('gcd(e,phi) = ${e.gcd(phi)}');
  print('phi bits=${phi.bitLength}');
}
