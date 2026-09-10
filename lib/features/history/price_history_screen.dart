import 'package:flutter/material.dart';
import 'package:lista_inteligente/core/database/database_helper.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class PriceHistoryScreen extends StatefulWidget {
  const PriceHistoryScreen({super.key});

  @override
  State<PriceHistoryScreen> createState() => _PriceHistoryScreenState();
}

class _PriceHistoryScreenState extends State<PriceHistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _priceRecords = [];
  List<String> _distinctItems = [];
  String? _selectedItemFilter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Busca histórico real do banco de dados
    final history = await _dbHelper.getLatestPriceComparison();
    final itemNames = await _dbHelper.getAllItemNames();

    if (!mounted) return;
    setState(() {
      _priceRecords = history;
      _distinctItems = itemNames;
      _isLoading = false;
    });
  }

  Future<void> _filterByProduct(String? productName) async {
    setState(() {
      _selectedItemFilter = productName;
      _isLoading = true;
    });

    if (productName == null || productName.isEmpty) {
      final history = await _dbHelper.getLatestPriceComparison();
      if (!mounted) return;
      setState(() {
        _priceRecords = history;
        _isLoading = false;
      });
    } else {
      final history = await _dbHelper.getItemPrices(productName);
      if (!mounted) return;
      setState(() {
        _priceRecords = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Comparativo de Preços', style: AppTypography.titleMedium),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Campo de busca por produto
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar produto para comparar...',
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: AppColors.textSecondary),
                  ),
                  onChanged: (val) {
                    _filterByProduct(val.trim());
                  },
                ),
              ),
            ),

            // Carrossel de Filtros Rápidos
            if (_distinctItems.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _distinctItems.length + 1,
                  itemBuilder: (ctx, idx) {
                    if (idx == 0) {
                      final isSelected = _selectedItemFilter == null;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: const Text('Todos'),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                          onSelected: (_) {
                            _searchController.clear();
                            _filterByProduct(null);
                          },
                        ),
                      );
                    }
                    final item = _distinctItems[idx - 1];
                    final isSelected = _selectedItemFilter == item;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(item),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        onSelected: (_) {
                          _searchController.text = item;
                          _filterByProduct(item);
                        },
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),

            // Lista do Comparativo
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _priceRecords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.find_in_page_outlined, size: 48, color: AppColors.textSecondary),
                              const SizedBox(height: 8),
                              Text(
                                'Nenhum histórico de preço registrado.',
                                style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _priceRecords.length,
                          itemBuilder: (context, index) {
                            final record = _priceRecords[index];
                            final double price = (record['price'] as num?)?.toDouble() ?? 0.0;
                            final String name = record['itemName'] ?? 'Produto';
                            final String store = record['supermarket'] ?? 'Mercado Desconhecido';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.storefront_outlined, color: AppColors.primary),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: AppTypography.titleMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}',
                                      style: AppTypography.titleMedium.copyWith(
                                        color: const Color(0xFF10B981),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        store,
                                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                      ),
                                      const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}