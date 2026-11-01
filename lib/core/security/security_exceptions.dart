class SecurityException implements Exception {
  final String message;

  const SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}

class InvalidKeyLengthException extends SecurityException {
  const InvalidKeyLengthException(String message) : super(message);
}

class InvalidCiphertextException extends SecurityException {
  const InvalidCiphertextException(String message) : super(message);
}

class AuthenticationFailedException extends SecurityException {
  const AuthenticationFailedException(String message) : super(message);
}
