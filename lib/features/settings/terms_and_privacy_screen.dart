import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class TermsAndPrivacyScreen extends StatelessWidget {
  const TermsAndPrivacyScreen({super.key});

  final String _webUrl = 'https://hudson483756.github.io/listainteligente-/';

  Future<void> _openWebUrl() async {
    final Uri url = Uri.parse(_webUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Não foi possível abrir a URL: $_webUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Termos e Privacidade', style: AppTypography.titleMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: AppColors.primary),
            tooltip: 'Abrir no navegador',
            onPressed: _openWebUrl,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Termos de Uso',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Aceitação dos Termos\n'
                  'Ao utilizar o aplicativo Lista Inteligente, você concorda com estes termos. O serviço destina-se ao gerenciamento pessoal e compartilhado de listas de compras.\n\n'
                  '2. Uso do Serviço\n'
                  'O usuário é responsável por manter a confidencialidade de sua conta e senha. É proibido utilizar o aplicativo para fins ilícitos ou não autorizados.',
                  style: AppTypography.caption.copyWith(fontSize: 13, height: 1.4),
                ),
                const Divider(height: 32),
                Text(
                  'Política de Privacidade',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Coleta de Dados\n'
                  'Coletamos informações como nome, e-mail e dados relacionados às suas listas de compras e históricos de preços para prover as funcionalidades do aplicativo.\n\n'
                  '2. Uso das Informações\n'
                  'Seus dados são armazenados de forma segura utilizando Firebase e SQLite local. Não compartilhamos suas informações pessoais com terceiros para fins publicitários.\n\n'
                  '3. Seus Direitos\n'
                  'Você pode solicitar a exclusão da sua conta ou limpar os dados locais salvos no dispositivo a qualquer momento pelas configurações.',
                  style: AppTypography.caption.copyWith(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openWebUrl,
                    icon: const Icon(Icons.language),
                    label: const Text('Ver Versão Online Completa'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}