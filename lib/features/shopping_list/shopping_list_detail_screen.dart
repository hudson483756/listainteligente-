import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lista_inteligente/core/database/database_helper.dart';
import 'package:lista_inteligente/features/items/presentation/screens/add_item_screen.dart';
import 'package:lista_inteligente/features/shopping_list/manage_members_dialog.dart';
import 'package:lista_inteligente/features/shopping_list/list_chat_screen.dart';
import 'package:lista_inteligente/services/firestore_service.dart';

class ShoppingListDetailScreen extends StatefulWidget {
  final String listId;
  final String listName;

  const ShoppingListDetailScreen({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<ShoppingListDetailScreen> createState() => _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends State<ShoppingListDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  CollectionReference get _itemsRef => FirebaseFirestore.instance
      .collection('listas')
      .doc(widget.listId)
      .collection('itens');

  Future<void> _deleteItem(String itemId) async {
    await _itemsRef.doc(itemId).delete();
  }

  Future<void> _deleteBoughtItems() async {
    final snapshot = await _itemsRef.where('isPurchased', isEqualTo: true).get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  void _confirmDeleteList() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Esta Lista'),
        content: Text('Tem certeza que deseja excluir "${widget.listName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestoreService.deleteList(widget.listId);
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Excluir Lista', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showFinalizeDialog(double estimatedTotal) async {
    final controller = TextEditingController(text: estimatedTotal.toStringAsFixed(2));

    final actualAmount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Finalizar "${widget.listName}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimado na lista: R\$ ${estimatedTotal.toStringAsFixed(2)}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor Real Pago (R\$)',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              final parsed = double.tryParse(controller.text.replaceAll(',', '.'));
              if (parsed != null && parsed >= 0) {
                Navigator.pop(ctx, parsed);
              }
            },
            child: const Text('Confirmar e Registrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (actualAmount != null) {
      await _firestoreService.finalizeList(widget.listId, widget.listName, actualAmount);
      await _dbHelper.addPurchase(actualAmount, 'Compra: ${widget.listName}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Compra finalizada! R\$ ${actualAmount.toStringAsFixed(2)} adicionados aos gastos.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  double _calculateItemTotal(double qty, double price, String unit) {
    final cleanUnit = unit.toLowerCase().trim();
    if (cleanUnit == 'g' || cleanUnit == 'gramas') {
      return (qty * price) / 1000.0;
    }
    return qty * price;
  }

  double _calculateTotalPrice(List<QueryDocumentSnapshot> docs) {
    double total = 0.0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final double qty = (data['quantity'] as num?)?.toDouble() ?? (data['quantidade'] as num?)?.toDouble() ?? 1.0;
      final double price = (data['price'] as num?)?.toDouble() ?? (data['preco'] as num?)?.toDouble() ?? 0.0;
      final String unit = (data['unit'] ?? data['unidade'] ?? 'un').toString();

      total += _calculateItemTotal(qty, price, unit);
    }
    return total;
  }

  void _openManageMembers() {
    showDialog(
      context: context,
      builder: (_) => ManageMembersDialog(listId: widget.listId),
    );
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListChatScreen(
          listId: widget.listId,
          listName: widget.listName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _itemsRef.snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final double totalPrice = _calculateTotalPrice(docs);

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.listName),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_outlined),
                tooltip: 'Bate-papo da Lista',
                onPressed: _openChat,
              ),
              IconButton(
                icon: const Icon(Icons.group_add),
                tooltip: 'Participantes e Código',
                onPressed: _openManageMembers,
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Remover Comprados',
                onPressed: _deleteBoughtItems,
              ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'delete_list') _confirmDeleteList();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'delete_list',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Excluir Lista', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: docs.isEmpty
                          ? const Center(child: Text('Nenhum item na lista.'))
                          : ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final String itemId = doc.id;
                                final String itemName = data['name'] ?? data['nome'] ?? 'Item';

                                final bool isDone = data['isPurchased'] ?? false;
                                final String? purchasedBy = data['purchasedBy'];
                                final double qty = (data['quantity'] as num?)?.toDouble() ?? (data['quantidade'] as num?)?.toDouble() ?? 1.0;
                                final String unit = data['unit'] ?? data['unidade'] ?? 'un';
                                final double price = (data['price'] as num?)?.toDouble() ?? (data['preco'] as num?)?.toDouble() ?? 0.0;
                                final double itemTotal = _calculateItemTotal(qty, price, unit);

                                final String qtyFormatted = qty % 1 == 0 ? qty.toInt().toString() : qty.toString();

                                return Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    leading: Checkbox(
                                      value: isDone,
                                      onChanged: (_) => _firestoreService.toggleItemPurchased(
                                        widget.listId,
                                        itemId,
                                        isDone,
                                        itemName,
                                      ),
                                    ),
                                    title: Text(
                                      itemName,
                                      style: TextStyle(
                                        decoration: isDone ? TextDecoration.lineThrough : null,
                                        color: isDone ? Colors.grey : Colors.black,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('$qtyFormatted $unit ${price > 0 ? '• R\$ ${price.toStringAsFixed(2)}/$unit' : ''}'),
                                        if (isDone && purchasedBy != null)
                                          Text(
                                            'Comprado por $purchasedBy',
                                            style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (itemTotal > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8.0),
                                            child: Text(
                                              'R\$ ${itemTotal.toStringAsFixed(2)}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 20),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => AddItemScreen(
                                                  listId: widget.listId,
                                                  itemToEdit: {...data, 'id': itemId},
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                          onPressed: () => _deleteItem(itemId),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Estimado:',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'R\$ ${totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                            label: const Text('Finalizar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () => _showFinalizeDialog(totalPrice),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddItemScreen(
                    listId: widget.listId,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}