class ItemPriceModel {
  final int? id;
  final int itemId;
  final int supermarketId;
  final String supermarketName;
  final double price;
  final DateTime updatedAt;

  ItemPriceModel({
    this.id,
    required this.itemId,
    required this.supermarketId,
    required this.supermarketName,
    required this.price,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  ItemPriceModel copyWith({
    int? id,
    int? itemId,
    int? supermarketId,
    String? supermarketName,
    double? price,
    DateTime? updatedAt,
  }) {
    return ItemPriceModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      supermarketId: supermarketId ?? this.supermarketId,
      supermarketName: supermarketName ?? this.supermarketName,
      price: price ?? this.price,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'itemId': itemId,
      'supermarketId': supermarketId,
      'price': price,
      'updatedAt': updatedAt.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory ItemPriceModel.fromMap(Map<String, dynamic> map) {
    return ItemPriceModel(
      id: map['id'] as int?,
      itemId: map['itemId'] as int? ?? 0,
      supermarketId: map['supermarketId'] as int? ?? 0,
      supermarketName: map['supermarketName'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ItemModel {
  final int? id;
  final int listId;
  final String name;
  final String category;
  final double quantity;
  final double price;
  final int? supermarketId;
  final String? supermarketName;
  final bool isBought;
  final DateTime createdAt;
  final List<ItemPriceModel> additionalPrices;

  ItemModel({
    this.id,
    required this.listId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.price,
    this.supermarketId,
    this.supermarketName,
    this.isBought = false,
    DateTime? createdAt,
    this.additionalPrices = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  double get total => quantity * price;

  ItemModel copyWith({
    int? id,
    int? listId,
    String? name,
    String? category,
    double? quantity,
    double? price,
    int? supermarketId,
    String? supermarketName,
    bool? isBought,
    DateTime? createdAt,
    List<ItemPriceModel>? additionalPrices,
  }) {
    return ItemModel(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      supermarketId: supermarketId ?? this.supermarketId,
      supermarketName: supermarketName ?? this.supermarketName,
      isBought: isBought ?? this.isBought,
      createdAt: createdAt ?? this.createdAt,
      additionalPrices: additionalPrices ?? this.additionalPrices,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'listId': listId,
      'name': name.trim(),
      'category': category.trim(),
      'quantity': quantity,
      'price': price,
      'supermarketId': supermarketId,
      'isBought': isBought ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    List<ItemPriceModel> parsedPrices = [];
    if (map['additionalPrices'] != null && map['additionalPrices'] is List) {
      parsedPrices = (map['additionalPrices'] as List)
          .map((p) => ItemPriceModel.fromMap(p as Map<String, dynamic>))
          .toList();
    }

    return ItemModel(
      id: map['id'] as int?,
      listId: map['listId'] as int? ?? 1,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      supermarketId: map['supermarketId'] as int?,
      supermarketName: map['supermarketName'] as String?,
      isBought: (map['isBought'] as int? ?? 0) == 1,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      additionalPrices: parsedPrices,
    );
  }
}