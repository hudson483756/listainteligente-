import 'package:flutter/material.dart';
import 'package:lista_inteligente/core/database/database_helper.dart';
import 'package:lista_inteligente/features/items/presentation/screens/add_item_screen.dart';
import 'package:lista_inteligente/features/items/presentation/screens/items_screen.dart';
import 'package:lista_inteligente/features/shopping_list/shopping_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  double _monthlySpent = 0.0;
  int _totalLists = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final spent = await _dbHelper.getMonthlySpent();
    final lists = await _dbHelper.getLists();
    if (!mounted) return;
    setState(() {
      _monthlySpent = spent;
      _totalLists = lists.length;
    });
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) => _loadDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Controle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo Geral',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.green.shade800,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gasto Total', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(
                            'R\$ ${_monthlySpent.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.blueGrey.shade800,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Minhas Listas', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(
                            '$_totalLists',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Ações Rápidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.format_list_bulleted, color: Colors.blue),
              title: const Text('Ver Listas de Compras'),
              subtitle: const Text('Gerencie suas listas ativas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateTo(const ShoppingListScreen()),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart, color: Colors.green),
              title: const Text('Adicionar Novo Item'),
              subtitle: const Text('Cadastre itens e preços rapidamente'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateTo(const AddItemScreen()),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.inventory_2, color: Colors.orange),
              title: const Text('Catálogo de Itens'),
              subtitle: const Text('Consulte o histórico de itens gravados'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateTo(const ItemsScreen()),
            ),
          ],
        ),
      ),
    );
  }
}