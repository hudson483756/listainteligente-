import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ExtractedVoiceItem {
  final String name;
  final double quantity;
  final String unit;
  final double price;
  final String category;
  final String supermarket;

  ExtractedVoiceItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.category,
    required this.supermarket,
  });

  factory ExtractedVoiceItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final parsedQty = parseDouble(json['quantity']);

    return ExtractedVoiceItem(
      name: json['productName']?.toString() ?? '',
      quantity: parsedQty <= 0 ? 1.0 : parsedQty,
      unit: json['unit']?.toString() ?? 'un',
      price: parseDouble(json['price']),
      category: json['category']?.toString() ?? 'Geral',
      supermarket: json['supermarket']?.toString() ?? '',
    );
  }
}

class GroqVoiceService {
  static const String _groqApiKey = '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';
  static const String _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';

  static Future<ExtractedVoiceItem?> parseSpokenText(String text) async {
    try {
      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'groq/compound-mini',
          'response_format': {'type': 'json_object'},
          'messages': [
            {
              'role': 'system',
              'content': '''
              Você é um assistente de extração de dados de compras.
              Extraia as informações e determine a unidade de medida adequada (ex: 'kg', 'g', 'un', 'ml', 'L'). Se não informada, use 'un'.
              Retorne APENAS um objeto JSON válido no seguinte formato:
              {
                "productName": "Nome do produto",
                "quantity": 1.0,
                "unit": "un",
                "price": 0.0,
                "category": "Categoria",
                "supermarket": ""
              }
              '''
            },
            {
              'role': 'user',
              'content': 'Extraia as informações da seguinte frase falada: "$text"'
            }
          ]
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        final Map<String, dynamic> parsedJson = jsonDecode(content);
        return ExtractedVoiceItem.fromJson(parsedJson);
      } else {
        debugPrint('Groq Voice Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erro Groq Voice: $e');
      return null;
    }
  }
}