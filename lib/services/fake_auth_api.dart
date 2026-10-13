import 'dart:convert';

/// Simula un backend que entrega un token por usuario.
/// En un proyecto real aquí iría una llamada HTTP que devuelve un JWT.
class FakeAuthApi {
  Future<String> issueToken(String username) async {
    await Future.delayed(const Duration(milliseconds: 500)); // "red"
    final payload = base64Url.encode(utf8.encode(username)).replaceAll('=', '');
    return 'eyJhbGciOiJIUzI1NiJ9.$payload.${DateTime.now().millisecondsSinceEpoch}';
  }
}