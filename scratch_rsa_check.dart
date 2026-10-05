import 'package:aircrypt/core/security/rsa.dart';
void main() {
  final pair = generateRsa2048KeyPairImpl();
  print('bitLength=${pair.modulus.bitLength}');
  final m = BigInt.parse('123456789012345678901234567890');
  final c = rsaPublicEncrypt(pair.publicKey, m);
  final d = rsaPrivateDecrypt(pair.privateKey, c);
  print('match=${m == d}');
  print('m=$m');
  print('d=$d');
}
