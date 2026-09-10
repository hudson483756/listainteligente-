import 'package:flutter/material.dart';

abstract class AppColors {
  // Tema Base
  static const Color background = Color(0xFF121214); // Dark Charcoal
  static const Color surface = Color(0xFF1E1E22);    // Dark Graphite
  static const Color surfaceLight = Color(0xFF2A2A30);

  // Tipografia & Bordas
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color border = Color(0xFF27272A);

  // Acentuações
  static const Color primary = Color(0xFF10B981);   // Emerald Mint (Economia/Ações)
  static const Color warning = Color(0xFFF59E0B);   // Amber Gold (Alertas/Desejos)
  static const Color danger = Color(0xFFEF4444);    // Rose Crimson (Débitos)
}