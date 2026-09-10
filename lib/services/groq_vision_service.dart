import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OfferExtractedItem {
  final String name;
  final String unit;
  final double price;
  final String category;
  final String? imagePath;

  OfferExtractedItem({
    required this.name,
    required this.unit,
    required this.price,
    required this.category,
    this.imagePath,
  });

  factory OfferExtractedItem.fromJson(Map<String, dynamic> json, {String? localImagePath}) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return OfferExtractedItem(
      name: json['productName']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'Unid.',
      price: parseDouble(json['price']),
      category: json['category']?.toString() ?? 'Geral',
      imagePath: localImagePath,
    );
  }
}

class GroqVisionService {
  static const String _groqApiKey = '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';
  static const String _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';

  static Future<List<OfferExtractedItem>> analyzeOfferImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final mimeType = imageFile.path.endsWith('.png') ? 'image/png' : 'image/jpeg';

      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'qwen/qwen3.6-27b',
          'response_format': {'type': 'json_object'},
          'messages': [
            {
              'role': 'system',
              'content': '''
              Analise a imagem deste encarte de ofertas.
              Retorne APENAS um JSON no formato:
              {
                "items": [
                  {
                    "productName": "Nome completo do produto",
                    "unit": "Unidade de medida ex: kg, un, ml",
                    "price": 0.0,
                    "category": "Categoria aproximada"
                  }
                ]
              }
              '''
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Identifique e liste TODOS os produtos visíveis com seus respectivos preços e unidades.'
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:$mimeType;base64,$base64Image'
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        final Map<String, dynamic> parsedJson = jsonDecode(content);
        final List<dynamic> itemsList = parsedJson['items'] ?? [];

        return itemsList
            .map((item) => OfferExtractedItem.fromJson(item, localImagePath: imageFile.path))
            .toList();
      } else {
        debugPrint('Erro Groq Vision API: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Erro ao analisar encarte via Groq Vision: $e');
      return [];
    }
  }
}