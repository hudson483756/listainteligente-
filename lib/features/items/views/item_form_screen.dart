import 'package:flutter/material.dart';
import 'package:lista_inteligente/core/database/database_helper.dart';

class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<String> _supermarkets = [];

  @override
  void initState() {
    super.initState();
    _loadSupermarkets();
  }

  Future<void> _loadSupermarkets() async {
    final rawSupermarkets = await _dbHelper.getAllSupermarkets();
    setState(() {
      _supermarkets = rawSupermarkets;
    });
  }

  Future<void> savePrice(int itemId, String supermarketName, double price) async {
    await _dbHelper.addOrUpdateItemPrice(
      itemId: itemId,
      supermarketName: supermarketName,
      price: price,
    );
  }

  Future<void> saveItem(Map<String, dynamic> itemData) async {
    await _dbHelper.insertItem(itemData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formulário de Item')),
      body: ListView.builder(
        itemCount: _supermarkets.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_supermarkets[index]),
          );
        },
      ),
    );
  }
}