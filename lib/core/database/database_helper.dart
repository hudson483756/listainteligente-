import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:lista_inteligente/core/constants/app_defaults.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDB('lista_inteligente.db');
    return _database!;
  }

  /// Permite fechar o banco de dados antes da mesclagem no SyncService
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE offers (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              price REAL NOT NULL,
              unit TEXT,
              category TEXT,
              imagePath TEXT,
              createdAt TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              iconName TEXT
            )
          ''');

          await db.execute('ALTER TABLE offers ADD COLUMN supermarket TEXT');
          await db.execute('ALTER TABLE offers ADD COLUMN validUntil TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE app_settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 5) {
          await db.execute("ALTER TABLE items ADD COLUMN unit TEXT NOT NULL DEFAULT 'un'");
        }
        if (oldVersion < 6) {
          // Suporte para controle de sincronização via nuvem
          await db.execute("ALTER TABLE shopping_lists ADD COLUMN updatedAt TEXT DEFAULT CURRENT_TIMESTAMP");
          await db.execute("ALTER TABLE items ADD COLUMN updatedAt TEXT DEFAULT CURRENT_TIMESTAMP");
          await db.execute("ALTER TABLE categories ADD COLUMN updatedAt TEXT DEFAULT CURRENT_TIMESTAMP");
          await db.execute("ALTER TABLE offers ADD COLUMN updatedAt TEXT DEFAULT CURRENT_TIMESTAMP");
        }
        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE purchases (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              amount REAL NOT NULL,
              description TEXT,
              date TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE shopping_lists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        listId INTEGER NOT NULL,
        name TEXT NOT NULL,
        category TEXT,
        supermarket TEXT,
        quantity REAL NOT NULL DEFAULT 1.0,
        unit TEXT NOT NULL DEFAULT 'un',
        price REAL NOT NULL DEFAULT 0.0,
        isPurchased INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (listId) REFERENCES shopping_lists (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE price_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        itemName TEXT NOT NULL,
        supermarket TEXT NOT NULL,
        price REAL NOT NULL,
        updatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE offers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        unit TEXT,
        category TEXT,
        supermarket TEXT,
        imagePath TEXT,
        validUntil TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        iconName TEXT,
        updatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        description TEXT,
        date TEXT NOT NULL
      )
    ''');
  }

  // --- MÉTODOS DE COMPRAS E REGISTRO DE GASTOS ---

  /// Registra uma nova compra no banco local
  Future<int> addPurchase(double amount, String description) async {
    final db = await instance.database;
    return await db.insert('purchases', {
      'amount': amount,
      'description': description,
      'date': DateTime.now().toIso8601String(),
    });
  }

  // --- MÉTODOS DE CONFIGURAÇÃO E ORÇAMENTO ---

  Future<double> getMonthlyBudget() async {
    final db = await instance.database;
    final res = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['monthly_budget'],
      limit: 1,
    );

    if (res.isNotEmpty) {
      return double.tryParse(res.first['value'] as String) ?? 1500.0;
    }
    return 1500.0;
  }

  Future<void> setMonthlyBudget(double budget) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    await db.insert(
      'app_settings',
      {'key': 'monthly_budget', 'value': budget.toString(), 'updatedAt': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- MÉTODOS DE OFERTAS ---

  Future<int> insertOffer(Map<String, dynamic> offerData) async {
    final db = await instance.database;
    final row = Map<String, dynamic>.from(offerData);
    row['updatedAt'] = DateTime.now().toIso8601String();
    return await db.insert('offers', row);
  }

  Future<List<Map<String, dynamic>>> getOffers() async {
    final db = await instance.database;
    return await db.query('offers', orderBy: 'id DESC');
  }

  Future<int> updateOffer(Map<String, dynamic> offerData) async {
    final db = await instance.database;
    final row = Map<String, dynamic>.from(offerData);
    final id = row['id'];
    row['updatedAt'] = DateTime.now().toIso8601String();
    return await db.update('offers', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteOffer(int id) async {
    final db = await instance.database;
    return await db.delete('offers', where: 'id = ?', whereArgs: [id]);
  }

  // --- MÉTODOS DE CATEGORIAS ---

  Future<int> insertCategory(String name, [String? iconName]) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    return await db.insert(
      'categories',
      {'name': name, 'iconName': iconName, 'updatedAt': now},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await instance.database;
    return await db.query('categories', orderBy: 'name ASC');
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // --- MÉTODOS DE LISTAS ---

  Future<List<Map<String, dynamic>>> getLists() async {
    final db = await instance.database;
    return await db.query('shopping_lists', orderBy: 'createdAt DESC');
  }

  Future<List<Map<String, dynamic>>> getAllLists() async {
    return await getLists();
  }

  Future<double> getMonthlySpent() async {
    final db = await instance.database;
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

    final res = await db.rawQuery(
      'SELECT SUM(amount) as total FROM purchases WHERE date >= ?',
      [firstDayOfMonth],
    );

    if (res.isNotEmpty && res.first['total'] != null) {
      return (res.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // --- MÉTODOS DE ITENS ---

  Future<Map<String, dynamic>?> findItemByNameAndList(String name, int listId) async {
    final db = await instance.database;
    final res = await db.query(
      'items',
      where: 'LOWER(name) = LOWER(?) AND listId = ?',
      whereArgs: [name.trim(), listId],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> insertItem(dynamic itemData, [dynamic extraArg]) async {
    final db = await instance.database;
    final Map<String, dynamic> row = itemData is Map<String, dynamic>
        ? Map<String, dynamic>.from(itemData)
        : (itemData.toMap != null ? Map<String, dynamic>.from(itemData.toMap()) : {});
    
    final now = DateTime.now().toIso8601String();
    row['unit'] ??= 'un';
    row['createdAt'] ??= now;
    row['updatedAt'] = now;
    return await db.insert('items', row);
  }

  Future<int> updateItem(dynamic itemData, [dynamic extraArg]) async {
    final db = await instance.database;
    final Map<String, dynamic> row = itemData is Map<String, dynamic>
        ? Map<String, dynamic>.from(itemData)
        : (itemData.toMap != null ? Map<String, dynamic>.from(itemData.toMap()) : {});
    final id = row['id'];
    row['updatedAt'] = DateTime.now().toIso8601String();
    return await db.update('items', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteItem(int id) async {
    final db = await instance.database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteBoughtItems([int? listId]) async {
    final db = await instance.database;
    if (listId != null) {
      return await db.delete(
        'items',
        where: 'listId = ? AND isPurchased = 1',
        whereArgs: [listId],
      );
    } else {
      return await db.delete('items', where: 'isPurchased = 1');
    }
  }

  Future<List<Map<String, dynamic>>> getItemsByList(int listId) async {
    final db = await instance.database;
    return await db.query(
      'items',
      where: 'listId = ?',
      whereArgs: [listId],
      orderBy: 'isPurchased ASC, id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllItems() async {
    final db = await instance.database;
    return await db.query('items', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> searchCatalog(String query) async {
    final db = await instance.database;
    return await db.query(
      'items',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      groupBy: 'name',
    );
  }

  Future<int> moveItemToList(int itemId, int targetListId) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    return await db.update(
      'items',
      {'listId': targetListId, 'updatedAt': now},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<int> copyItemToList(Map<String, dynamic> item, int targetListId) async {
    final newItem = Map<String, dynamic>.from(item);
    newItem.remove('id');
    newItem['listId'] = targetListId;
    final now = DateTime.now().toIso8601String();
    newItem['createdAt'] = now;
    newItem['updatedAt'] = now;
    
    return await insertItem(newItem);
  }

  // --- MÉTODOS DE FILTROS E SUGESTÕES ---

  Future<List<String>> getAllSupermarkets() async {
    final db = await instance.database;
    final res = await db.rawQuery(
      'SELECT DISTINCT supermarket FROM items WHERE supermarket IS NOT NULL AND supermarket != ""'
    );
    return res.map((e) => e['supermarket'] as String).toList();
  }

  Future<List<String>> getAllItemNames() async {
    final db = await instance.database;
    final res = await db.rawQuery('SELECT DISTINCT name FROM items');
    return res.map((e) => e['name'] as String).toList();
  }

  Future<List<String>> getAllCategories() async {
    final db = await instance.database;
    final res = await db.rawQuery(
      'SELECT DISTINCT category FROM items WHERE category IS NOT NULL AND category != ""'
    );
    return res.map((e) => e['category'] as String).toList();
  }

  // --- MÉTODOS DE AUTOCOMPLETE ---

  Future<List<String>> getAllListTitles() async {
    final db = await instance.database;
    final res = await db.rawQuery('SELECT DISTINCT name FROM shopping_lists WHERE name IS NOT NULL AND name != ""');
    return res.map((e) => e['name'] as String).toList();
  }

  Future<List<String>> getAutocompleteItems() async {
    final db = await instance.database;
    final resItems = await db.rawQuery('SELECT DISTINCT name FROM items WHERE name IS NOT NULL AND name != ""');
    final resOffers = await db.rawQuery('SELECT DISTINCT name FROM offers WHERE name IS NOT NULL AND name != ""');

    final Set<String> suggestions = {};
    
    suggestions.addAll(AppDefaults.defaultItems);

    for (var row in resItems) {
      if (row['name'] != null) suggestions.add(row['name'] as String);
    }
    for (var row in resOffers) {
      if (row['name'] != null) suggestions.add(row['name'] as String);
    }

    final list = suggestions.toList()..sort();
    return list;
  }

  Future<List<String>> getAutocompleteCategories() async {
    final db = await instance.database;
    final resCatTable = await db.rawQuery('SELECT DISTINCT name FROM categories WHERE name IS NOT NULL AND name != ""');
    final resItems = await db.rawQuery('SELECT DISTINCT category FROM items WHERE category IS NOT NULL AND category != ""');

    final Set<String> suggestions = {};
    
    suggestions.addAll(AppDefaults.defaultCategories);

    for (var row in resCatTable) {
      if (row['name'] != null) suggestions.add(row['name'] as String);
    }
    for (var row in resItems) {
      if (row['category'] != null) suggestions.add(row['category'] as String);
    }

    final list = suggestions.toList()..sort();
    return list;
  }

  Future<List<String>> getAutocompleteSupermarkets() async {
    final db = await instance.database;
    final resItems = await db.rawQuery('SELECT DISTINCT supermarket FROM items WHERE supermarket IS NOT NULL AND supermarket != ""');
    final resOffers = await db.rawQuery('SELECT DISTINCT supermarket FROM offers WHERE supermarket IS NOT NULL AND supermarket != ""');
    final resHistory = await db.rawQuery('SELECT DISTINCT supermarket FROM price_history WHERE supermarket IS NOT NULL AND supermarket != ""');

    final Set<String> suggestions = {};

    for (var row in resItems) {
      if (row['supermarket'] != null) suggestions.add(row['supermarket'] as String);
    }
    for (var row in resOffers) {
      if (row['supermarket'] != null) suggestions.add(row['supermarket'] as String);
    }
    for (var row in resHistory) {
      if (row['supermarket'] != null) suggestions.add(row['supermarket'] as String);
    }

    final list = suggestions.toList()..sort();
    return list;
  }

  // --- MÉTODOS DE HISTÓRICO DE PREÇOS ---

  Future<void> addOrUpdateItemPrice({
    int? itemId,
    required String supermarketName,
    required double price,
    String? itemName,
  }) async {
    final db = await instance.database;
    final String name = itemName ?? 'Item_$itemId';
    
    final existing = await db.query(
      'price_history',
      where: 'itemName = ? AND supermarket = ?',
      whereArgs: [name, supermarketName],
    );

    final data = {
      'itemName': name,
      'supermarket': supermarketName,
      'price': price,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (existing.isNotEmpty) {
      await db.update(
        'price_history',
        data,
        where: 'itemName = ? AND supermarket = ?',
        whereArgs: [name, supermarketName],
      );
    } else {
      await db.insert('price_history', data);
    }
  }

  Future<List<Map<String, dynamic>>> getItemPrices(dynamic itemIdOrName) async {
    final db = await instance.database;
    final String queryName = itemIdOrName.toString();
    return await db.query(
      'price_history',
      where: 'itemName = ?',
      whereArgs: [queryName],
      orderBy: 'price ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getLatestPriceComparison() async {
    final db = await instance.database;
    return await db.query('price_history', orderBy: 'updatedAt DESC');
  }
}