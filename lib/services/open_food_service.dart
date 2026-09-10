import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class OpenFoodService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';

  /// Busca o produto pelo código de barras.
  /// Retorna o [ProductModel] se encontrado ou `null` se não existir na base.
  static Future<ProductModel?> fetchProductByBarcode(String barcode) async {
    final url = Uri.parse('$_baseUrl/$barcode.json');

    try {
      final response = await http.get(
        url,
        headers: {
          // EXIGÊNCIA CRÍTICA DO OPEN FOOD FACTS: Identificação do app
          'User-Agent': 'ListaInteligente - Android/iOS - Version 1.0 - contato@listainteligente.com',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // O Open Food Facts indica sucesso na busca através da propriedade 'status' == 1
        if (data['status'] == 1 && data['product'] != null) {
          return ProductModel.fromJson(barcode, data['product']);
        }
      }
      return null; // Produto não encontrado
    } catch (e) {
      throw Exception('Erro ao conectar com a API do Open Food Facts: $e');
    }
  }
}