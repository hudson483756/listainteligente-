import 'package:flutter/material.dart';
import 'package:lista_inteligente/core/database/database_helper.dart';
import 'package:lista_inteligente/features/items/presentation/screens/items_screen.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _lists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLists();
  }

  Future<void> _fetchLists() async {
    setState(() => _isLoading = true);
    final lists = await _dbHelper.getLists();
    setState(() {
      _lists = lists;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA5D8F6).withValues(alpha: 0.3),
      appBar: AppBar(
        title: const Text(
          'Minhas Listas',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lists.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma lista cadastrada ainda.',
                    style: TextStyle(fontSize: 16, color: Color(0xFF334155)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lists.length,
                  itemBuilder: (context, index) {
                    final list = _lists[index];
                    final int listId = list['id'] as int;
                    final String listName = list['name'] ?? 'Lista sem nome';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFD1E9FF),
                          child: Icon(Icons.shopping_cart, color: Color(0xFF1E3A8A)),
                        ),
                        title: Text(
                          listName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          list['createdAt'] != null
                              ? 'Criada em: ${list['createdAt'].toString().substring(0, 10)}'
                              : 'Lista ativa',
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemsScreen(
                                listId: listId,
                                listName: listName,
                              ),
                            ),
                          ).then((_) => _fetchLists());
                        },
                      ),
                    );
                  },
                ),
    );
  }
}