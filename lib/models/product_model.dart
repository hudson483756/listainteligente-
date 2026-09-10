class ProductModel {
  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final String categories;

  ProductModel({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.categories,
  });

  factory ProductModel.fromJson(String barcode, Map<String, dynamic> json) {
    return ProductModel(
      barcode: barcode,
      name: json['product_name'] ?? 'Nome não informado',
      brand: json['brands'] ?? 'Marca desconhecida',
      imageUrl: json['image_url'] ?? '',
      categories: json['categories'] ?? 'Sem categoria',
    );
  }
}