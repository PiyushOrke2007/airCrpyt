import 'rsa.dart';
import 'secure_random.dart';

class KeyGeneration {
  const KeyGeneration();

  static List<int> generateAes256Key() {
    return SecureRandom.nextBytes(32);
  }

  static Rsa2048KeyPair generateRsa2048KeyPair() {
    return generateRsa2048KeyPairImpl();
  }
}
