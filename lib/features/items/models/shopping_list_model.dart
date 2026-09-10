class ShoppingListModel {
  final int? id;
  final String name;
  final bool isFinished;
  final String createdAt;
  final double total; // Para exibir o total no Dashboard

  ShoppingListModel({
    this.id,
    required this.name,
    this.isFinished = false,
    required this.createdAt,
    this.total = 0.0,
  });

  factory ShoppingListModel.fromMap(Map<String, dynamic> map) {
    return ShoppingListModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      isFinished: (map['isFinished'] as int?) == 1,
      createdAt: map['createdAt'] as String,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'isFinished': isFinished ? 1 : 0,
      'createdAt': createdAt,
    };
  }
}