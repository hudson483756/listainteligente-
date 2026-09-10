import 'package:flutter/material.dart';
import 'package:lista_inteligente/core/database/database_helper.dart';

class ItemsScreen extends StatefulWidget {
  final int? listId;
  final String? listName;

  const ItemsScreen({
    super.key,
    this.listId,
    this.listName,
  });

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    List<Map<String, dynamic>> rawItems;

    if (widget.listId != null) {
      rawItems = await _dbHelper.getItemsByList(widget.listId!);
    } else {
      rawItems = await _dbHelper.getAllItems();
    }

    if (!mounted) return;
    setState(() {
      _items = rawItems;
      _isLoading = false;
    });
  }

  Future<void> _deleteBought() async {
    await _dbHelper.deleteBoughtItems(widget.listId);
    _loadItems();
  }

  Future<void> _toggleItemPurchased(Map<String, dynamic> item) async {
    final int currentStatus = (item['isPurchased'] as num? ?? 0).toInt();
    final int newStatus = currentStatus == 1 ? 0 : 1;

    final updatedItem = Map<String, dynamic>.from(item);
    updatedItem['isPurchased'] = newStatus;

    await _dbHelper.updateItem(updatedItem);
    _loadItems();
  }

  double get _totalEstimated {
    return _items.fold(0.0, (sum, item) {
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final quantity = (item['quantity'] as num?)?.toDouble() ?? 1.0;
      return sum + (price * quantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    final int itemCount = _items.length;
    final double totalValue = _totalEstimated;

    return Scaffold(
      backgroundColor: const Color(0xFFA5D8F6).withValues(alpha: 0.3),
      appBar: AppBar(
        title: Text(
          widget.listName ?? 'Itens da Lista',
          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Color(0xFF1E293B)),
            onPressed: _deleteBought,
            tooltip: 'Remover comprados',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum item nesta lista.',
                    style: TextStyle(fontSize: 16, color: Color(0xFF334155)),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
                          
                          // Conversão segura do tipo num/double para double/int sem crashar
                          final double quantity = (item['quantity'] as num?)?.toDouble() ?? 1.0;
                          final bool isPurchased = (item['isPurchased'] as num? ?? 0).toInt() == 1;

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              leading: Checkbox(
                                value: isPurchased,
                                activeColor: const Color(0xFF2C4A6F),
                                onChanged: (_) => _toggleItemPurchased(item),
                              ),
                              title: Text(
                                item['name']?.toString() ?? 'Sem nome',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: isPurchased ? TextDecoration.lineThrough : null,
                                  color: isPurchased ? Colors.grey : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                'Qtd: ${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2)} | Unit: R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: TextStyle(
                                  decoration: isPurchased ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              trailing: Text(
                                'R\$ ${(price * quantity).toStringAsFixed(2).replaceAll('.', ',')}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isPurchased ? Colors.grey : const Color(0xFF15803D),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Card Exibidor dos Totais da Lista
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Total Estimado: $itemCount itens | R\$ ${totalValue.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}