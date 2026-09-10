class SupermarketModel {
  final int? id;
  final String name;

  SupermarketModel({
    this.id,
    required this.name,
  });

  /// Converte o modelo em um Map para inserir/atualizar no SQLite
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name.trim(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Cria uma instância do SupermarketModel a partir do resultado do SQLite
  factory SupermarketModel.fromMap(Map<String, dynamic> map) {
    return SupermarketModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
    );
  }

  /// Cria uma cópia do modelo alterando apenas os campos necessários
  SupermarketModel copyWith({
    int? id,
    String? name,
  }) {
    return SupermarketModel(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupermarketModel && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => 'SupermarketModel(id: $id, name: $name)';
}