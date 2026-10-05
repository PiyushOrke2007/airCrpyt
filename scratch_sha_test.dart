import 'dart:typed_data';
import 'package:aircrypt/core/security/sha256.dart';

void main() {
  final digest = Sha256Service.digest(Uint8List.fromList('abc'.codeUnits));
  print(digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join());
  print(Sha256Service.digest([]).map((b) => b.toRadixString(16).padLeft(2, '0')).join());
}
