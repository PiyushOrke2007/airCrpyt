import 'dart:convert';

class JsonPayload {
  static List<int> encode(
      Map<String, dynamic> data,
      ) {
    return utf8.encode(
      jsonEncode(data),
    );
  }

  static Map<String, dynamic> decode(
      List<int> data,
      ) {
    final jsonString = utf8.decode(data);

    final decoded = jsonDecode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Payload is not a JSON object.',
      );
    }

    return decoded;
  }
}
