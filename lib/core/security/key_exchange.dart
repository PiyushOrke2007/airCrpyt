class KeyExchangeVersion {
  static const int v1 = 1;
}

class KeyExchangeMetadata {
  final int version;
  final String rsaAlgorithm;
  final List<int> encryptedAesKey;

  const KeyExchangeMetadata({
    required this.version,
    required this.rsaAlgorithm,
    required this.encryptedAesKey,
  });

  Map<String, dynamic> toJson() => {
    'keyExchangeVersion': version,
    'rsaAlgorithm': rsaAlgorithm,
    'encryptedAesKey': encryptedAesKey
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .toList(),
  };
}
