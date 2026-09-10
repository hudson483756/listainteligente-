import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lista_inteligente/core/database/database_helper.dart';
import 'package:lista_inteligente/services/firestore_service.dart';
import 'package:lista_inteligente/services/groq_vision_service.dart';
import 'package:lista_inteligente/features/shopping_list/shopping_list_detail_screen.dart';
import 'package:lista_inteligente/features/shopping_list/manage_members_dialog.dart';
import 'package:lista_inteligente/features/items/presentation/screens/barcode_scanner_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  double _monthlyBudget = 1500.0;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final budget = await _dbHelper.getMonthlyBudget();
    if (mounted) {
      setState(() => _monthlyBudget = budget);
    }
  }

  IconData _getCategoryIcon(String listName) {
    final name = listName.toLowerCase();
    if (name.contains('supermercado')) return Icons.shopping_cart_outlined;
    if (name.contains('farmácia') || name.contains('padaria')) return Icons.local_pharmacy_outlined;
    if (name.contains('churrasco')) return Icons.local_fire_department_outlined;
    if (name.contains('limpeza')) return Icons.cleaning_services_outlined;
    if (name.contains('feira')) return Icons.shopping_basket_outlined;
    return Icons.shopping_bag_outlined;
  }

  void _showScannerOptionsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escanear ou Tirar Foto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner, color: Colors.teal, size: 30),
                title: const Text('Escanear Código de Barras'),
                subtitle: const Text('Consulta produto via Open Food Facts'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openBarcodeScanner();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.deepOrange, size: 30),
                title: const Text('Tirar Foto do Produto'),
                subtitle: const Text('Identifica produto e preço com Groq AI'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openProductPhotoScanner();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openBarcodeScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      _showAddScannedItemModal(
        name: result['name'] ?? '',
        category: result['category'] ?? 'Geral',
        price: (result['price'] ?? 0.0).toDouble(),
        unit: 'un',
      );
    }
  }

  void _openProductPhotoScanner() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Analisando produto com Groq AI...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final items = await GroqVisionService.analyzeOfferImage(File(image.path));
      if (!mounted) return;
      Navigator.pop(context);

      if (items.isNotEmpty) {
        final item = items.first;
        _showAddScannedItemModal(
          name: item.name,
          category: item.category,
          price: item.price,
          unit: item.unit,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum produto identificado na imagem.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao analisar foto: $e')),
      );
    }
  }

  void _showAddScannedItemModal({
    required String name,
    required String category,
    required double price,
    required String unit,
  }) async {
    final nameController = TextEditingController(text: name);
    final priceController = TextEditingController(text: price.toStringAsFixed(2));
    final qtyController = TextEditingController(text: '1');
    String selectedUnit = unit;

    final snapshot = await FirebaseFirestore.instance.collection('listas').get();
    final userLists = snapshot.docs.map((doc) => {'id': doc.id, 'name': (doc.data()['nome'] ?? 'Sem nome').toString()}).toList();

    String? selectedListId = userLists.isNotEmpty ? userLists.first['id'] : null;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Confirmar Produto Escaneado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedListId,
                          decoration: const InputDecoration(labelText: 'Selecione a Lista', border: OutlineInputBorder()),
                          items: userLists.map((l) => DropdownMenuItem(value: l['id'], child: Text(l['name']!))).toList(),
                          onChanged: (val) => setModalState(() => selectedListId = val),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                        onPressed: () async {
                          final newController = TextEditingController();
                          final newId = await showDialog<String>(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              title: const Text('Nova Lista'),
                              content: TextField(controller: newController, decoration: const InputDecoration(labelText: 'Nome')),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancelar')),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (newController.text.trim().isNotEmpty) {
                                      final doc = await FirebaseFirestore.instance.collection('listas').add({
                                        'nome': newController.text.trim(),
                                        'createdAt': FieldValue.serverTimestamp(),
                                      });
                                      if (dCtx.mounted) Navigator.pop(dCtx, doc.id);
                                    }
                                  },
                                  child: const Text('Criar'),
                                )
                              ],
                            ),
                          );
                          if (newId != null) {
                            final freshSnap = await FirebaseFirestore.instance.collection('listas').get();
                            userLists.clear();
                            userLists.addAll(freshSnap.docs.map((d) => {'id': d.id, 'name': (d.data()['nome'] ?? 'Sem nome').toString()}));
                            setModalState(() => selectedListId = newId);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome do Produto', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantidade', border: OutlineInputBorder()))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Preço (R\$)', border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), minimumSize: const Size.fromHeight(48)),
                    onPressed: () async {
                      if (selectedListId == null || nameController.text.trim().isEmpty) return;

                      await FirebaseFirestore.instance
                          .collection('listas')
                          .doc(selectedListId)
                          .collection('itens')
                          .add({
                        'name': nameController.text.trim(),
                        'quantity': double.tryParse(qtyController.text) ?? 1.0,
                        'unit': selectedUnit,
                        'price': double.tryParse(priceController.text.replaceAll(',', '.')) ?? price,
                        'category': category,
                        'isPurchased': false,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item adicionado à lista!'), backgroundColor: Colors.green));
                      }
                    },
                    child: const Text('Adicionar à Lista', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showJoinListDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Entrar em uma Lista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cole o ID ou código da lista compartilhada para se inscrever:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Código / ID da Lista',
                hintText: 'Ex: abc123XYZ...',
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            onPressed: () async {
              final listId = controller.text.trim();
              if (listId.isNotEmpty) {
                Navigator.pop(ctx);
                try {
                  await _firestoreService.joinList(listId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Você entrou na lista com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao entrar na lista: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Entrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showFinalizeDialog(String listId, String listName, double estimatedTotal) async {
    final controller = TextEditingController(text: estimatedTotal.toStringAsFixed(2));

    final actualAmount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Finalizar "$listName"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estimado na lista: R\$ ${estimatedTotal.toStringAsFixed(2)}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
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
      await _firestoreService.finalizeList(listId, listName, actualAmount);
      await _dbHelper.addPurchase(actualAmount, 'Compra: $listName');
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

  Widget _buildBudgetSummaryHeader(List<QueryDocumentSnapshot> allDocs) {
    return FutureBuilder<List<double>>(
      future: Future.wait(allDocs.map((doc) async {
        final itemsSnap = await FirebaseFirestore.instance
            .collection('listas')
            .doc(doc.id)
            .collection('itens')
            .get();

        double listTotal = 0.0;
        for (var itemDoc in itemsSnap.docs) {
          final data = itemDoc.data();
          final double price = ((data['preco'] ?? data['price']) ?? 0.0).toDouble();
          final double qtd = ((data['quantidade'] ?? data['quantity']) ?? 1.0).toDouble();
          final String unit = ((data['unidade'] ?? data['unit']) ?? 'un').toString().toLowerCase();

          if (unit == 'g' || unit == 'gramas') {
            listTotal += (price * qtd) / 1000.0;
          } else {
            listTotal += price * qtd;
          }
        }
        return listTotal;
      })),
      builder: (context, snapshot) {
        final List<double> listTotals = snapshot.data ?? [];
        final double sumAllLists = listTotals.isEmpty
            ? 0.0
            : listTotals.reduce((value, element) => value + element);

        final double pctSpent = _monthlyBudget > 0 ? (sumAllLists / _monthlyBudget).clamp(0.0, 1.0) : 0.0;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Impacto Geral no Orçamento',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Icon(Icons.pie_chart_outline, color: Color(0xFF38BDF8)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Soma das Listas', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      Text('R\$ ${sumAllLists.toStringAsFixed(2)}',
                          style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Orçamento Geral', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      Text('R\$ ${_monthlyBudget.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pctSpent,
                  minHeight: 10,
                  backgroundColor: const Color(0xFF334155),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    pctSpent >= 1.0 ? Colors.redAccent : const Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Suas listas comprometem ${(pctSpent * 100).toStringAsFixed(1)}% do seu orçamento.',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListStream(Stream<QuerySnapshot> stream, {required bool isSharedTab}) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final allDocs = snapshot.data?.docs ?? [];
        final docs = isSharedTab
            ? allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['donoId'] != currentUid;
              }).toList()
            : allDocs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Nenhuma lista encontrada.', style: TextStyle(color: Colors.white70)),
                if (isSharedTab) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                    onPressed: _showJoinListDialog,
                    icon: const Icon(Icons.group_add, color: Colors.white),
                    label: const Text('Entrar em uma Lista', style: TextStyle(color: Colors.white)),
                  )
                ]
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final String listId = doc.id;
            final String listName = data['nome'] ?? 'Sem nome';
            final bool isFinalized = data['isFinalized'] ?? false;
            final bool isOwner = data['donoId'] == currentUid;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('listas')
                  .doc(listId)
                  .collection('itens')
                  .snapshots(),
              builder: (context, itemSnapshot) {
                double listTotal = 0.0;
                int totalItems = 0;

                if (itemSnapshot.hasData) {
                  totalItems = itemSnapshot.data!.docs.length;
                  for (var itemDoc in itemSnapshot.data!.docs) {
                    final itemData = itemDoc.data() as Map<String, dynamic>;
                    final double price = ((itemData['preco'] ?? itemData['price']) ?? 0.0).toDouble();
                    final double qtd = ((itemData['quantidade'] ?? itemData['quantity']) ?? 1.0).toDouble();
                    final String unit = ((itemData['unidade'] ?? itemData['unit']) ?? 'un').toString().toLowerCase();

                    if (unit == 'g' || unit == 'gramas') {
                      listTotal += (price * qtd) / 1000.0;
                    } else {
                      listTotal += price * qtd;
                    }
                  }
                }

                final double listConsumptionPct =
                    _monthlyBudget > 0 ? (listTotal / _monthlyBudget) * 100 : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isFinalized ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFDCEEFA),
                          child: Icon(_getCategoryIcon(listName), color: const Color(0xFF1E3A8A)),
                        ),
                        title: Text(
                          listName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$totalItems itens • Total: R\$ ${listTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: Color(0xFF0284C7), fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Consome ${listConsumptionPct.toStringAsFixed(1)}% do orçamento',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShoppingListDetailScreen(listId: listId, listName: listName),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share, color: Color(0xFF0284C7), size: 20),
                            tooltip: 'Compartilhar Lista',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => ManageMembersDialog(listId: listId),
                              );
                            },
                          ),
                          if (!isFinalized)
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20),
                              tooltip: 'Finalizar Compra',
                              onPressed: () => _showFinalizeDialog(listId, listName, listTotal),
                            ),
                          if (isOwner)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              tooltip: 'Excluir Lista',
                              onPressed: () async {
                                await _firestoreService.deleteList(listId);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF334155),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Listas de Compras', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.group_add, color: Colors.white),
              tooltip: 'Entrar em uma Lista',
              onPressed: _showJoinListDialog,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Color(0xFF38BDF8),
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFF94A3B8),
            labelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(text: 'Minhas Listas'),
              Tab(text: 'Compartilhadas'),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.getLists(),
          builder: (context, snapshot) {
            final allDocs = snapshot.data?.docs ?? [];
            return Column(
              children: [
                _buildBudgetSummaryHeader(allDocs),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildListStream(_firestoreService.getMyLists(), isSharedTab: false),
                      _buildListStream(_firestoreService.getSharedLists(), isSharedTab: true),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF0284C7),
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            if (index == 3) {
              _showScannerOptionsModal();
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.format_list_bulleted), label: 'Listas'),
            BottomNavigationBarItem(icon: Icon(Icons.local_offer_outlined), label: 'Ofertas'),
            BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scanner'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}