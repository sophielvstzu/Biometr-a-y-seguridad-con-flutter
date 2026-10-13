import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cliente mínimo de la API de Gemini (REST).
/// La API key NO está en el código: llega desde flutter_secure_storage.
class AiService {
  // Si este modelo deja de existir, revisa ai.google.dev/gemini-api/docs/models
  // y cambia solo esta línea (ej. gemini-2.5-flash-lite).
  static const String model = 'gemini-2.5-flash';

  // Historial para que el modelo recuerde la conversación.
  final List<Map<String, dynamic>> _history = [];

  Future<String> ask(String apiKey, String prompt) async {
    _history.add({'role': 'user', 'parts': [{'text': prompt}]});

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
    );

    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey, // la key viaja en el header
          },
          body: jsonEncode({
            'systemInstruction': {
              'parts': [
                {'text': 'Eres un asistente de seguridad móvil. Responde en español, claro y en máximo 5 líneas.'}
              ]
            },
            'contents': _history,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      _history.removeLast(); // no guardamos el mensaje si falló
      throw Exception('Error ${res.statusCode}: revisa tu API key o el modelo');
    }

    final data = jsonDecode(res.body);
    final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
    _history.add({'role': 'model', 'parts': [{'text': text}]});
    return text;
  }
}