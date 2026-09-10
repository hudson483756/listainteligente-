import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';

class SupermarketScreen extends StatefulWidget {
  const SupermarketScreen({super.key});

  @override
  State<SupermarketScreen> createState() => _SupermarketScreenState();
}

class _SupermarketScreenState extends State<SupermarketScreen> {
  List<Map<String, dynamic>> _comparisonData = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadComparison();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Busca o histórico/comparativo mais recente diretamente do DatabaseHelper
  Future<void> _loadComparison() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseHelper.instance.getLatestPriceComparison();
      if (!mounted) return;
      setState(() {
        _comparisonData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar comparativo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF121418);
    const cardColor = Color(0xFF1E222A);
    const primaryGreen = Color(0xFF00D285);
    const textColor = Colors.white;
    const subTextColor = Color(0xFF9EA6B2);

    // Filtra por nome do produto digitado na busca
    final filteredData = _comparisonData.where((item) {
      final productName = (item['item_name'] ?? '').toString().toLowerCase();
      return productName.contains(_searchQuery.toLowerCase());
    }).toList();

    // Agrupa os preços por nome de produto para exibir lado a lado
    final Map<String, List<Map<String, dynamic>>> groupedProducts = {};
    for (var row in filteredData) {
      final pName = row['item_name'] as String;
      if (!groupedProducts.containsKey(pName)) {
        groupedProducts[pName] = [];
      }
      groupedProducts[pName]!.add(row);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Comparativo de Preços',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: textColor),
            onPressed: _loadComparison,
          ),
        ],
      ),
      body: Column(
        children: [
          // Campo de Busca
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: textColor),
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Filtrar por produto...',
                  hintStyle: TextStyle(color: subTextColor),
                  icon: Icon(Icons.search, color: subTextColor),
                ),
              ),
            ),
          ),

          // Lista de Comparação
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  )
                : groupedProducts.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum histórico encontrado.',
                          style: TextStyle(color: subTextColor, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: groupedProducts.keys.length,
                        itemBuilder: (context, index) {
                          final productName = groupedProducts.keys.elementAt(index);
                          final marketPrices = groupedProducts[productName]!;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: primaryGreen,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      productName,
                                      style: const TextStyle(
                                        color: textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(color: Color(0xFF2C323E), height: 1),
                                const SizedBox(height: 8),

                                // Lista dos mercados onde o item foi registrado
                                ...marketPrices.asMap().entries.map((entry) {
                                  final isBestPrice = entry.key == 0; // O SQL já vem ordenado por menor preço
                                  final item = entry.value;
                                  final price = (item['avg_price'] as num).toDouble();
                                  final supermarket = item['supermarket_name'] ?? 'Geral';

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              supermarket,
                                              style: TextStyle(
                                                color: isBestPrice ? primaryGreen : subTextColor,
                                                fontWeight: isBestPrice ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                            if (isBestPrice && marketPrices.length > 1) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: primaryGreen.withAlpha(30),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Mais Barato',
                                                  style: TextStyle(
                                                    color: primaryGreen,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}',
                                          style: TextStyle(
                                            color: isBestPrice ? primaryGreen : textColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}