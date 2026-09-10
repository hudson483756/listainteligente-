import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // Dados simulados de compras passadas
  final List<Map<String, dynamic>> _historyData = const [
    {
      'id': 'h1',
      'title': 'Compras da Semana',
      'date': '15/08/2026',
      'store': 'Supermercado Carrefour',
      'total': 348.90,
      'itemCount': 16,
      'hasNfce': true,
    },
    {
      'id': 'h2',
      'title': 'Churrasco de Domingo',
      'date': '10/08/2026',
      'store': 'Açougue & Cia',
      'total': 215.50,
      'itemCount': 7,
      'hasNfce': true,
    },
    {
      'id': 'h3',
      'title': 'Feira Semanal',
      'date': '03/08/2026',
      'store': 'Hortifruti da Vovó',
      'total': 84.20,
      'itemCount': 12,
      'hasNfce': false,
    },
    {
      'id': 'h4',
      'title': 'Farmácia e Higiene',
      'date': '28/07/2026',
      'store': 'Drogaria Pacheco',
      'total': 142.00,
      'itemCount': 5,
      'hasNfce': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final double totalMonthSpend = _historyData.fold(
      0.0,
      (sum, item) => sum + (item['total'] as double),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Histórico de Compras', style: AppTypography.titleMedium),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de resumo do mês no histórico
              _buildMonthlySummaryCard(totalMonthSpend, _historyData.length),
              const SizedBox(height: 24),

              Text('Compras Anteriores', style: AppTypography.titleMedium),
              const SizedBox(height: 12),

              // Lista das compras finalizadas
              ..._historyData.map((purchase) => _buildHistoryTile(context, purchase)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlySummaryCard(double totalSpend, int count) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Registrado no Mês', style: AppTypography.caption),
              const SizedBox(height: 4),
              Text(
                'R\$ ${totalSpend.toStringAsFixed(2)}',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  '$count',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text('Compras', style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(BuildContext context, Map<String, dynamic> purchase) {
    final bool hasNfce = purchase['hasNfce'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.primary,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                purchase['title'] as String,
                style: AppTypography.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'R\$ ${(purchase['total'] as double).toStringAsFixed(2)}',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase['store'] as String,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${purchase['date']} • ${purchase['itemCount']} itens',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasNfce
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasNfce ? Icons.qr_code_2 : Icons.edit_note,
                      size: 12,
                      color: hasNfce ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasNfce ? 'NFC-e' : 'Manual',
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: hasNfce ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Detalhes da compra "${purchase['title']}"'),
              backgroundColor: AppColors.surface,
            ),
          );
        },
      ),
    );
  }
}