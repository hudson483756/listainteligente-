import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lista_inteligente/core/database/database_helper.dart';
import 'package:lista_inteligente/services/firestore_service.dart';
import 'package:lista_inteligente/features/items/presentation/screens/add_item_screen.dart';
import 'package:lista_inteligente/features/shopping_list/shopping_list_screen.dart';
import 'package:lista_inteligente/features/items/presentation/screens/offers_import_screen.dart';
import 'package:lista_inteligente/features/items/presentation/screens/barcode_scanner_screen.dart';
import 'package:lista_inteligente/features/profile/profile_screen.dart';
import 'package:lista_inteligente/features/shopping_list/shopping_list_detail_screen.dart';
import 'package:lista_inteligente/features/history/price_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FirestoreService _firestoreService = FirestoreService();

  double _monthlySpent = 0.0;
  double _budgetLimit = 1500.0;
  List<Map<String, dynamic>> _userOffers = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final spent = await _dbHelper.getMonthlySpent();
    final budget = await _dbHelper.getMonthlyBudget();
    final offers = await _dbHelper.getOffers();

    if (mounted) {
      setState(() {
        _monthlySpent = spent;
        _budgetLimit = budget;
        _userOffers = offers;
      });
    }
  }

  Future<void> _testarConexaoFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final String userEmail = user?.email?.toLowerCase() ?? 'teste@exemplo.com';

      await FirebaseFirestore.instance.collection('listas').add({
        'nome': 'Lista de Teste Cloud',
        'donoEmail': userEmail,
        'membros': [userEmail],
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conexão OK! Documento gravado no Firestore.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de Conexão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editBudgetDialog() async {
    final controller = TextEditingController(text: _budgetLimit.toStringAsFixed(2));

    final newBudget = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterar Orçamento Mensal'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Novo Teto de Gastos (R\$)',
            prefixText: 'R\$ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.replaceAll(',', '.'));
              if (parsed != null && parsed > 0) {
                Navigator.pop(ctx, parsed);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (newBudget != null) {
      await _dbHelper.setMonthlyBudget(newBudget);
      _loadDashboardData();
    }
  }

  Future<void> _openListsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShoppingListScreen()),
    );
    _loadDashboardData();
  }

  void _onBottomTabTapped(int index) {
    if (index == _currentIndex) return;

    if (index == 1) {
      _openListsScreen();
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OffersImportScreen()),
      ).then((_) => _loadDashboardData());
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      ).then((_) => _loadDashboardData());
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double remaining = _budgetLimit - _monthlySpent;
    final double progress = _budgetLimit > 0 ? (_monthlySpent / _budgetLimit).clamp(0.0, 1.0) : 0.0;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? FirebaseAuth.instance.currentUser;
        final String displayName = (user?.displayName != null && user!.displayName!.isNotEmpty)
            ? user.displayName!
            : 'Usuário';
        final String? photoUrl = user?.photoURL;

        return Scaffold(
          backgroundColor: const Color(0xFFEAF5FC),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF2C4A6F),
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
              ),
            ),
            title: const Text(
              'Lista Inteligente',
              style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 20),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.cloud_sync, color: Color(0xFF0284C7)),
                onPressed: _testarConexaoFirestore,
                tooltip: 'Testar Conexão Firebase',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $displayName!',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const Text(
                  'Pronto para economizar?',
                  style: TextStyle(fontSize: 15, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Resumo do Mês',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF0284C7)),
                      onPressed: _editBudgetDialog,
                      tooltip: 'Ajustar Orçamento',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _editBudgetDialog,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEEFA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Visão Geral', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              Text('Tocar para alterar', style: TextStyle(fontSize: 11, color: Color(0xFF0284C7))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 85,
                                    height: 85,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 9,
                                      backgroundColor: Colors.white.withValues(alpha: 0.6),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        progress >= 1.0 ? Colors.red : const Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Gasto', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                      Text(
                                        'R\$ ${_monthlySpent.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Gasto Atual', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                            Text('R\$ ${_monthlySpent.toStringAsFixed(2)}',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('Teto', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                            Text('R\$ ${_budgetLimit.toStringAsFixed(2)}',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 8,
                                        backgroundColor: Colors.white.withValues(alpha: 0.6),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          progress >= 1.0 ? Colors.red : const Color(0xFF10B981),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      remaining >= 0
                                          ? 'R\$ ${remaining.toStringAsFixed(2)} disponíveis'
                                          : 'R\$ ${remaining.abs().toStringAsFixed(2)} acima do teto',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: remaining >= 0 ? const Color(0xFF0284C7) : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_userOffers.isNotEmpty) ...[
                  const Text('Ofertas Salvas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _userOffers.length,
                      itemBuilder: (context, index) {
                        final offer = _userOffers[index];
                        final String? imagePath = offer['imagePath'];
                        return Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCEEFA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    image: imagePath != null
                                        ? DecorationImage(
                                            image: FileImage(File(imagePath)),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: imagePath == null
                                      ? const Center(child: Icon(Icons.local_offer, color: Color(0xFF0284C7)))
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                offer['name'] ?? 'Oferta',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                'R\$ ${(offer['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Minhas Listas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    TextButton(
                      onPressed: _openListsScreen,
                      child: const Text('Ver Todas', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestoreService.getLists(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Text(
                        'Erro ao carregar as listas em tempo real.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Text(
                        'Nenhuma lista encontrada. Crie uma para começar!',
                        style: TextStyle(color: Color(0xFF64748B)),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final String name = data['nome'] ?? 'Lista';
                          final String docId = doc.id;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: _buildListCard(
                              icon: Icons.shopping_bag_outlined,
                              iconBg: const Color(0xFFBCE3F7),
                              iconColor: const Color(0xFF0284C7),
                              title: name,
                              subtitle: '',
                              details: 'Abrir lista',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ShoppingListDetailScreen(
                                      listId: docId,
                                      listName: name,
                                    ),
                                  ),
                                ).then((_) => _loadDashboardData());
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text('Ações Rápidas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _openListsScreen,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCEEFA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.shopping_cart_outlined, size: 32, color: Color(0xFF0284C7)),
                              SizedBox(height: 6),
                              Text('Ver Lista', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                              Text('de Compras', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddItemScreen()),
                          );
                          _loadDashboardData();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCEEFA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.add_shopping_cart, size: 32, color: Color(0xFF10B981)),
                              SizedBox(height: 6),
                              Text('Adicionar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                              Text('Novo Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PriceHistoryScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCEEFA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.compare_arrows, size: 32, color: Color(0xFFF59E0B)),
                              SizedBox(height: 6),
                              Text('Comparar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                              Text('Preços', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onBottomTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF0284C7),
            unselectedItemColor: const Color(0xFF64748B),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.format_list_bulleted), label: 'Listas'),
              BottomNavigationBarItem(icon: Icon(Icons.local_offer_outlined), label: 'Ofertas'),
              BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scanner'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String details,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFDCEEFA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: iconBg,
              radius: 18,
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                Text(details, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 20),
          ],
        ),
      ),
    );
  }
}