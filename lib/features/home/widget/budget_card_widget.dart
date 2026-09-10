import 'package:flutter/material.dart';
import 'package:lista_inteligente/core/database/database_helper.dart';

class BudgetCardWidget extends StatefulWidget {
  const BudgetCardWidget({super.key});

  @override
  State<BudgetCardWidget> createState() => _BudgetCardWidgetState();
}

class _BudgetCardWidgetState extends State<BudgetCardWidget> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  double _monthlyBudget = 1500.0;
  double _monthlySpent = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    setState(() => _isLoading = true);
    final budget = await _dbHelper.getMonthlyBudget();
    final spent = await _dbHelper.getMonthlySpent();

    if (mounted) {
      setState(() {
        _monthlyBudget = budget;
        _monthlySpent = spent;
        _isLoading = false;
      });
    }
  }

  Future<void> _openEditBudgetDialog() async {
    final controller = TextEditingController(
      text: _monthlyBudget.toStringAsFixed(2),
    );

    final newBudget = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Orçamento Mensal'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Teto Financeiro (R\$)',
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
              final cleanText = controller.text
                  .replaceAll('R\$', '')
                  .replaceAll(' ', '')
                  .replaceAll(',', '.');
              final val = double.tryParse(cleanText);
              if (val != null && val >= 0) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (newBudget != null) {
      await _dbHelper.setMonthlyBudget(newBudget);
      _loadBudgetData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final double progress = (_monthlyBudget > 0)
        ? (_monthlySpent / _monthlyBudget).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Orçamento Geral',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Color(0xFF2563EB)),
                  onPressed: _openEditBudgetDialog,
                  tooltip: 'Editar Teto Financeiro',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gasto: R\$ ${_monthlySpent.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  'Teto: R\$ ${_monthlyBudget.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 0.9 ? Colors.red : const Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}