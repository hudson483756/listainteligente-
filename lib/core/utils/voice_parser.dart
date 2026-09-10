class ParsedVoiceItem {
  final double quantity;
  final String name;
  final double? price;

  ParsedVoiceItem({
    required this.quantity,
    required this.name,
    this.price,
  });
}

class VoiceParser {
  static ParsedVoiceItem parse(String input) {
    String text = input.toLowerCase().trim();

    final Map<String, double> numberWords = {
      'um': 1.0, 'uma': 1.0,
      'dois': 2.0, 'duas': 2.0,
      'três': 3.0, 'tres': 3.0,
      'quatro': 4.0, 'cinco': 5.0,
      'seis': 6.0, 'sete': 7.0,
      'oito': 8.0, 'nove': 9.0, 'dez': 10.0,
    };

    double quantity = 1.0;
    double? price;

    // 1. Extrair Preço (ex: r$ 9, 9 reais, 9.50)
    final priceMatch = RegExp(r'(?:r\$|reais)\s*(\d+(?:[\.,]\d+)?)').firstMatch(text) ??
                       RegExp(r'(\d+(?:[\.,]\d+)?)\s*(?:reais|real|r\$)').firstMatch(text);

    if (priceMatch != null) {
      String rawPrice = priceMatch.group(1)!.replaceAll(',', '.');
      price = double.tryParse(rawPrice);
    }

    // 2. Remover prefixos comuns de voz
    String cleaned = text.replaceAll(RegExp(r'^(comprei|adicione|coloque|peguei)\s+'), '');

    // 3. Extrair Quantidade no início
    final words = cleaned.split(' ');
    if (words.isNotEmpty) {
      final firstWord = words.first;
      if (RegExp(r'^\d+$').hasMatch(firstWord)) {
        quantity = double.parse(firstWord);
        cleaned = words.sublist(1).join(' ');
      } else if (numberWords.containsKey(firstWord)) {
        quantity = numberWords[firstWord]!;
        cleaned = words.sublist(1).join(' ');
      }
    }

    // 4. Limpar o nome restante isolando o produto
    String name = cleaned
        .replaceAll(RegExp(r'\s*(?:por|custando|de)\s*(?:r\$)?\s*\d+.*$'), '')
        .replaceAll(RegExp(r'\s*(?:r\$)?\s*\d+\s*(?:reais|real)?.*$'), '')
        .trim();

    if (name.isNotEmpty) {
      name = name[0].toUpperCase() + name.substring(1);
    }

    return ParsedVoiceItem(
      quantity: quantity,
      name: name.isEmpty ? input : name,
      price: price,
    );
  }
}