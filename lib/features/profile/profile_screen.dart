import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lista_inteligente/core/database/database_helper.dart';
import 'package:lista_inteligente/services/groq_test_service.dart';
import 'package:lista_inteligente/features/notifications/notifications_screen.dart';
import 'package:lista_inteligente/features/history/purchase_history_screen.dart';
import 'package:lista_inteligente/features/settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  double _currentBudget = 1500.0;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final budget = await _dbHelper.getMonthlyBudget();
    if (mounted) {
      setState(() {
        _currentBudget = budget;
      });
    }
  }

  Future<void> _editBudgetDialog() async {
    final controller = TextEditingController(text: _currentBudget.toStringAsFixed(2));

    final newBudget = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Definir Orçamento Mensal'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Teto de Gastos (R\$)',
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
      _loadBudget();
    }
  }

  void _runApiTest(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Testando conexão com a API Groq...')),
    );

    final result = await GroqTestService.testApiConnection();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Diagnóstico Groq API'),
        content: SingleChildScrollView(
          child: SelectableText(result),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? FirebaseAuth.instance.currentUser;
        final String displayName = (user?.displayName != null && user!.displayName!.isNotEmpty)
            ? user.displayName!
            : 'Usuário';
        final String email = user?.email ?? 'usuario@email.com';
        final String? photoUrl = user?.photoURL;

        return Scaffold(
          backgroundColor: const Color(0xFFA5D8F6).withValues(alpha: 0.3),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Meu Perfil',
              style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF2C4A6F),
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(
                  email,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF0284C7)),
                        title: const Text('Orçamento Mensal'),
                        subtitle: Text('R\$ ${_currentBudget.toStringAsFixed(2)}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _editBudgetDialog,
                      ),
                      const Divider(height: 1),
                      ListTile(
                          leading: const Icon(Icons.notifications_none, color: Color(0xFF0284C7)),
                          title: const Text('Notificações e Alertas'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                            );
                          },
                        ),
                      const Divider(height: 1),
                      ListTile(
                          leading: const Icon(Icons.history, color: Color(0xFF0284C7)),
                          title: const Text('Histórico de Compras'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PurchaseHistoryScreen()),
                            );
                          },
                        ),
                      const Divider(height: 1),
                      ListTile(
                          leading: const Icon(Icons.settings_outlined, color: Color(0xFF0284C7)),
                          title: const Text('Configurações'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SettingsScreen()),
                            );
                          },
                        ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.api_outlined, color: Color(0xFF10B981)),
                        title: const Text('Testar Conexão com a IA Groq'),
                        subtitle: const Text('Diagnóstico da chave API e resposta'),
                        trailing: const Icon(Icons.play_arrow_rounded, color: Color(0xFF10B981)),
                        onTap: () => _runApiTest(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}