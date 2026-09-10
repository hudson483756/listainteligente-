import 'package:flutter/material.dart';

Widget buildStatementTabContent(Color customGreen, double monthlySpent) {
  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text('Histórico de Compras', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161A22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(Icons.receipt_long, color: customGreen, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Resumo Mensal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('Total gasto até agora', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            Text(
              'R\$ ${monthlySpent.toStringAsFixed(2)}',
              style: TextStyle(color: customGreen, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    ],
  );
}