import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lista_inteligente/services/open_food_service.dart';
import 'package:lista_inteligente/models/product_model.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isProcessing = false;
  int _attemptsLeft = 3;
  ProductModel? _scannedProduct;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing || _attemptsLeft <= 0) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawCode = barcodes.first.rawValue;
    if (rawCode == null || rawCode.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final product = await OpenFoodService.fetchProductByBarcode(rawCode);

      if (mounted) {
        setState(() {
          _scannedProduct = product ??
              ProductModel(
                barcode: rawCode,
                name: 'Produto não cadastrado ($rawCode)',
                brand: 'Desconhecida',
                imageUrl: '',
                categories: 'Geral',
              );
          _attemptsLeft = (_attemptsLeft - 1).clamp(0, 3);
        });
      }
    } catch (e) {
      _showSnackBar('Erro ao buscar o código de barras.');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _confirmAndReturn() {
    if (_scannedProduct == null) return;
    Navigator.pop(context, {
      'name': _scannedProduct!.name,
      'category': _scannedProduct!.categories,
      'price': 0.0,
      'barcode': _scannedProduct!.barcode,
    });
  }

  void _resetScanner() {
    setState(() {
      _scannedProduct = null;
    });
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F4FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scanner de Código de Barras',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircleAvatar(
                backgroundColor: Color(0xFF2C4A6F),
                radius: 24,
                child: Icon(Icons.person, color: Colors.white, size: 28),
              ),
              SizedBox(width: 12),
              Text(
                'Código de Barras',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              SizedBox(width: 8),
              Icon(Icons.flatware, size: 30, color: Color(0xFF8C6239)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: MobileScanner(
                      controller: _scannerController,
                      onDetect: _onBarcodeDetected,
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 260,
                      height: 160,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 2,
                            width: double.infinity,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isProcessing)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  if (_scannedProduct != null)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'Item Encontrado!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nome do Produto: ${_scannedProduct!.name}',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
                            ),
                            Text(
                              'Marca: ${_scannedProduct!.brand}',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                minimumSize: const Size.fromHeight(44),
                              ),
                              onPressed: _confirmAndReturn,
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: const Text(
                                'Confirmar Produto',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Tentativas Restantes: $_attemptsLeft',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _resetScanner,
                                  child: const Text('Escanear outro'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Aproxime o código de barras da câmera',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}