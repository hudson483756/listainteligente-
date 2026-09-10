import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lista_inteligente/services/firestore_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class PurchaseHistoryScreen extends StatelessWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Histórico de Compras', style: AppTypography.titleMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: firestoreService.getSharedLists(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'Nenhum histórico encontrado.',
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                ),
              );
            }

            // Filtra apenas as listas finalizadas
            final finalizedDocs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['isFinalized'] == true;
            }).toList();

            if (finalizedDocs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history_toggle_off, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhuma compra finalizada ainda.',
                      style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            // Calcula o gasto total acumulado das listas finalizadas
            final double totalSpend = finalizedDocs.fold<double>(0.0, (acc, doc) {
              final data = doc.data() as Map<String, dynamic>;
              return acc + ((data['finalizedAmount'] as num?)?.toDouble() ?? 0.0);
            });

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card de resumo do mês
                  _buildMonthlySummaryCard(totalSpend, finalizedDocs.length),
                  const SizedBox(height: 24),

                  Text('Compras Anteriores', style: AppTypography.titleMedium),
                  const SizedBox(height: 12),

                  // Lista dinâmica de compras finalizadas
                  ...finalizedDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final String listName = data['nome'] ?? 'Lista sem nome';
                    final double amount = (data['finalizedAmount'] as num?)?.toDouble() ?? 0.0;
                    final String finalizedBy = data['finalizedBy'] ?? 'Usuário';

                    final Timestamp? timestamp = data['finalizedAt'] as Timestamp?;
                    final String dateFormatted = timestamp != null
                        ? DateFormat('dd/MM/yyyy').format(timestamp.toDate())
                        : 'Data não informada';

                    return _buildHistoryTile(
                      context,
                      title: listName,
                      date: dateFormatted,
                      finalizedBy: finalizedBy,
                      total: amount,
                    );
                  }),
                ],
              ),
            );
          },
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
              Text('Total Registrado', style: AppTypography.caption),
              const SizedBox(height: 4),
              Text(
                'R\$ ${totalSpend.toStringAsFixed(2).replaceAll('.', ',')}',
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

  Widget _buildHistoryTile(
    BuildContext context, {
    required String title,
    required String date,
    required String finalizedBy,
    required double total,
  }) {
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
                title,
                style: AppTypography.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Finalizado por: $finalizedBy',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}