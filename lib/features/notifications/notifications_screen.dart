import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lista_inteligente/services/firestore_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _budgetAlerts = true;
  bool _listUpdates = true;
  bool _promotionalAlerts = false;
  bool _isLoadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _budgetAlerts = prefs.getBool('pref_budget_alerts') ?? true;
      _listUpdates = prefs.getBool('pref_list_updates') ?? true;
      _promotionalAlerts = prefs.getBool('pref_promotional_alerts') ?? false;
      _isLoadingPrefs = false;
    });
  }

  Future<void> _togglePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      if (key == 'pref_budget_alerts') _budgetAlerts = value;
      if (key == 'pref_list_updates') _listUpdates = value;
      if (key == 'pref_promotional_alerts') _promotionalAlerts = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA5D8F6).withValues(alpha: 0.3),
      appBar: AppBar(
        title: const Text('Notificações e Alertas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solicitações de Ingresso em Listas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getMyLists(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Você ainda não possui listas criadas.', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                final List<Widget> pendingRequestsList = [];

                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String listId = doc.id;
                  final String listName = data['nome'] ?? 'Lista';
                  final Map pending = data['solicitacoesPendentes'] ?? {};

                  pending.forEach((applicantUid, applicantData) {
                    pendingRequestsList.add(
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.orangeAccent,
                            child: Icon(Icons.person_add, color: Colors.white),
                          ),
                          title: Text(applicantData['nome'] ?? 'Convidado'),
                          subtitle: Text('Solicitou entrar em "$listName"'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                                onPressed: () async {
                                  await _firestoreService.acceptMember(listId, applicantUid, applicantData);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${applicantData['nome']} aceito em $listName!')),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
                                onPressed: () async {
                                  await _firestoreService.rejectMember(listId, applicantUid);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Solicitação recusada.')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  });
                }

                if (pendingRequestsList.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green),
                          SizedBox(width: 12),
                          Expanded(child: Text('Nenhuma solicitação pendente no momento.')),
                        ],
                      ),
                    ),
                  );
                }

                return Column(children: pendingRequestsList);
              },
            ),

            const SizedBox(height: 24),
            const Text(
              'Preferências de Alertas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            _isLoadingPrefs
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Avisos de Orçamento'),
                          subtitle: const Text('Receber alertas ao atingir 80% do limite configurado'),
                          secondary: const Icon(Icons.account_balance_wallet, color: Color(0xFF0284C7)),
                          value: _budgetAlerts,
                          onChanged: (val) => _togglePreference('pref_budget_alerts', val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Atualizações de Lista'),
                          subtitle: const Text('Notificar sobre novos itens adicionados por convidados'),
                          secondary: const Icon(Icons.playlist_add_check, color: Color(0xFF0284C7)),
                          value: _listUpdates,
                          onChanged: (val) => _togglePreference('pref_list_updates', val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Ofertas e Sugestões'),
                          subtitle: const Text('Dicas automáticas baseadas nos seus itens frequentes'),
                          secondary: const Icon(Icons.local_offer, color: Color(0xFF0284C7)),
                          value: _promotionalAlerts,
                          onChanged: (val) => _togglePreference('pref_promotional_alerts', val),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}