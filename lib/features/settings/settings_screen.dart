import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import 'package:lista_inteligente/features/settings/terms_and_privacy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _pushNotifications = true;
  bool _emailAlerts = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Configurações', style: AppTypography.titleMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Seção Preferências do App
            _buildSectionHeader('Preferências'),
            _buildCardWrapper([
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                title: const Text('Tema Escuro'),
                subtitle: const Text('Alternar para visual escuro'),
                value: _darkMode,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => _darkMode = val);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                title: const Text('Notificações Push'),
                subtitle: const Text('Receber alertas de ofertas e listas'),
                value: _pushNotifications,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => _pushNotifications = val);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.mail_outline, color: AppColors.primary),
                title: const Text('Resumos por E-mail'),
                subtitle: const Text('Receber histórico mensal de compras'),
                value: _emailAlerts,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => _emailAlerts = val);
                },
              ),
            ]),

            const SizedBox(height: 24),

            // Seção Conta e Segurança
            _buildSectionHeader('Conta e Dados'),
            _buildCardWrapper([
              ListTile(
                leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                title: const Text('Alterar Senha'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('E-mail de redefinição enviado!')),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Excluir Dados Locais', style: TextStyle(color: Colors.redAccent)),
                onTap: () => _showDeleteConfirmationDialog(context),
              ),
            ]),

            const SizedBox(height: 24),

            // Seção Sobre
            _buildSectionHeader('Sobre'),
            _buildCardWrapper([
              const ListTile(
                leading: Icon(Icons.info_outline, color: AppColors.primary),
                title: Text('Versão do Aplicativo'),
                trailing: Text('1.0.0', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              ),
              const Divider(height: 1),
              ListTile(
  leading: const Icon(Icons.security, color: AppColors.primary),
  title: Text(
    'Termos de Uso e Privacidade',
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white, // Corrigido para ficar visível no fundo escuro
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TermsAndPrivacyScreen()),
          );
        },
      ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTypography.titleMedium.copyWith(
          fontSize: 14,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCardWrapper(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar Dados Locais'),
        content: const Text('Tem certeza de que deseja limpar o cache do aplicativo? Nenhuma compra finalizada no nuvem será perdida.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache limpo com sucesso!')),
              );
            },
            child: const Text('Limpar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}