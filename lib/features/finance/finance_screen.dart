import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const double budgetLimit = 2000.00;
    const double totalSpent = 1250.40;
    const double remaining = budgetLimit - totalSpent;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Gestão Financeira', style: AppTypography.titleMedium),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Principal: Resumo do Orçamento
              _buildMainBudgetCard(budgetLimit, totalSpent, remaining),
              const SizedBox(height: 24),

              // Seção: Gastos por Categoria
              Text('Gastos por Categoria', style: AppTypography.titleMedium),
              const SizedBox(height: 12),
              _buildCategoryBreakdown(),
              const SizedBox(height: 24),

              // Seção: Divisão no Grupo Familiar
              Text('Divisão da Família', style: AppTypography.titleMedium),
              const SizedBox(height: 12),
              _buildFamilyMemberSpending(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainBudgetCard(double limit, double spent, double remaining) {
    final double percentUsed = (spent / limit) * 100;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mês de Agosto', style: AppTypography.caption),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${percentUsed.toStringAsFixed(0)}% Utilizado',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gastos Atuais', style: AppTypography.caption),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${spent.toStringAsFixed(2)}',
                    style: AppTypography.titleLarge.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Restante', style: AppTypography.caption),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${remaining.toStringAsFixed(2)}',
                    style: AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: spent / limit,
              minHeight: 10,
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final List<Map<String, dynamic>> categories = [
      {
        'name': 'Mercearia & Alimentos',
        'amount': 680.50,
        'percent': 0.54,
        'color': AppColors.primary,
        'icon': Icons.restaurant,
      },
      {
        'name': 'Higiene & Limpeza',
        'amount': 290.00,
        'percent': 0.23,
        'color': Colors.blueAccent,
        'icon': Icons.cleaning_services,
      },
      {
        'name': 'Laticínios & Frios',
        'amount': 180.00,
        'percent': 0.14,
        'color': Colors.amberAccent,
        'icon': Icons.local_drink,
      },
      {
        'name': 'Snacks & Bebidas',
        'amount': 99.90,
        'percent': 0.08,
        'color': Colors.orangeAccent,
        'icon': Icons.fastfood,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (cat['color'] as Color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    cat['icon'] as IconData,
                    color: cat['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(cat['name'] as String, style: AppTypography.bodyLarge),
                          Text(
                            'R\$ ${(cat['amount'] as double).toStringAsFixed(2)}',
                            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: cat['percent'] as double,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: AlwaysStoppedAnimation<Color>(cat['color'] as Color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFamilyMemberSpending() {
    final List<Map<String, dynamic>> members = [
      {'name': 'Silva (Você)', 'amount': 820.40, 'initial': 'S'},
      {'name': 'Maria', 'amount': 430.00, 'initial': 'M'},
    ];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: members.map((member) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.surfaceLight,
              child: Text(
                member['initial'] as String,
                style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
              ),
            ),
            title: Text(member['name'] as String, style: AppTypography.bodyLarge),
            trailing: Text(
              'R\$ ${(member['amount'] as double).toStringAsFixed(2)}',
              style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
            ),
          );
        }).toList(),
      ),
    );
  }
}