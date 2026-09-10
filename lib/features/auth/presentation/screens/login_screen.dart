import 'package:flutter/material.dart';
import 'package:lista_inteligente/services/auth_service.dart';
import 'package:lista_inteligente/features/home/views/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isCheckingGoogle = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isCheckingGoogle = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (!mounted) return;

      if (userCredential != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao conectar com Google: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingGoogle = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 80,
                      color: Color(0xFF0284C7),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Lista Inteligente',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Organize suas compras de forma prática e rápida',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton.icon(
                      onPressed: _isCheckingGoogle ? null : _handleGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F172A),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        elevation: 1,
                      ),
                      icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.red),
                      label: const Text(
                        'Entrar com o Google',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Modal de carregamento com o GIF
          if (_isCheckingGoogle)
            Container(
              color: Colors.black.withValues(alpha: 0.65),
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/carrinho.gif',
                      width: 120,
                      height: 120,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.shopping_cart,
                          size: 80,
                          color: Colors.white,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Validando conta do Google...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}