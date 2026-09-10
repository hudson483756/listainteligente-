import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqTestService {
  static const String _groqApiKey = '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';

  static Future<String> testApiConnection() async {
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'groq/compound-mini',
          'messages': [
            {'role': 'user', 'content': 'Responda apenas: OK'}
          ]
        }),
      );

      if (response.statusCode == 200) {
        return 'SUCCESS 200: Conexão com a Groq API estabelecida com sucesso!';
      } else {
        return 'ERRO HTTP ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      return 'FALHA DE CONEXÃO: $e';
    }
  }
}