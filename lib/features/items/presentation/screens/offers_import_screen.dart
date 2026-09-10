import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lista_inteligente/core/database/database_helper.dart';
import 'package:lista_inteligente/services/groq_vision_service.dart';

class OffersImportScreen extends StatefulWidget {
  const OffersImportScreen({super.key});

  @override
  State<OffersImportScreen> createState() => _OffersImportScreenState();
}

class _OffersImportScreenState extends State<OffersImportScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ImagePicker _picker = ImagePicker();

  bool _isProcessing = false;
  List<OfferExtractedItem> _detectedOffers = [];
  int? _targetListId;

  @override
  void initState() {
    super.initState();
    _loadDefaultList();
  }

  Future<void> _loadDefaultList() async {
    final lists = await _dbHelper.getLists();
    if (lists.isNotEmpty && mounted) {
      setState(() {
        _targetListId = lists.first['id'] as int?;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() {
      _isProcessing = true;
    });

    final extractedItems = await GroqVisionService.analyzeOfferImage(File(image.path));

    for (var item in extractedItems) {
      await _dbHelper.insertOffer({
        'name': item.name,
        'price': item.price,
        'unit': item.unit,
        'category': item.category,
        'imagePath': image.path,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    if (mounted) {
      setState(() {
        _detectedOffers = extractedItems;
        _isProcessing = false;
      });
      if (extractedItems.isEmpty) {
        _showSnackBar('Nenhum produto identificado no encarte.');
      }
    }
  }

  void _removeItem(int index) {
    setState(() {
      _detectedOffers.removeAt(index);
    });
  }

  Future<void> _addSingleItem(OfferExtractedItem item) async {
    if (_targetListId == null) {
      final lists = await _dbHelper.getLists();
      if (lists.isNotEmpty) {
        _targetListId = lists.first['id'] as int;
      } else {
        _showSnackBar('Crie uma lista de compras primeiro.');
        return;
      }
    }

    await _dbHelper.insertItem({
      'listId': _targetListId,
      'name': item.name,
      'category': item.category,
      'supermarket': 'Encarte Galeria',
      'quantity': 1,
      'price': item.price,
      'isPurchased': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });

    _showSnackBar('${item.name} adicionado!');
  }

  Future<void> _importAll() async {
    if (_detectedOffers.isEmpty) {
      _showSnackBar('Nenhuma oferta para importar.');
      return;
    }

    if (_targetListId == null) {
      final lists = await _dbHelper.getLists();
      if (lists.isNotEmpty) {
        _targetListId = lists.first['id'] as int;
      } else {
        _showSnackBar('Crie uma lista de compras primeiro.');
        return;
      }
    }

    for (var item in _detectedOffers) {
      await _dbHelper.insertItem({
        'listId': _targetListId,
        'name': item.name,
        'category': item.category,
        'supermarket': 'Encarte Galeria',
        'quantity': 1,
        'price': item.price,
        'isPurchased': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    if (!mounted) return;
    _showSnackBar('${_detectedOffers.length} itens importados com sucesso!');
    Navigator.pop(context);
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
          'Importar Ofertas (Galeria)',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF1E293B)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircleAvatar(
                    backgroundColor: Color(0xFF2C4A6F),
                    radius: 22,
                    child: Icon(Icons.person, color: Colors.white, size: 26),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Ofertas da Galeria',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.flatware, size: 28, color: Color(0xFF8C6239)),
                ],
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'Importe ofertas de imagens da sua galeria',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, size: 32, color: Color(0xFF2C4A6F)),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _pickImage(ImageSource.gallery),
                        child: const Text(
                          'Área de Importação',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const Text(
                        'Tire uma foto do encarte ou importe da Galeria',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isProcessing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _detectedOffers.length,
                itemBuilder: (context, index) {
                  final item = _detectedOffers[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(12),
                                image: item.imagePath != null
                                    ? DecorationImage(
                                        image: FileImage(File(item.imagePath!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: item.imagePath == null
                                  ? const Icon(Icons.shopping_bag, size: 40, color: Color(0xFF0284C7))
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFBAE6FD),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              onPressed: () => _addSingleItem(item),
                              icon: const Icon(Icons.add, size: 14, color: Color(0xFF0369A1)),
                              label: const Text(
                                'Adicionar',
                                style: TextStyle(fontSize: 11, color: Color(0xFF0369A1), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Nome do Produto: ${item.name}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _removeItem(index),
                                    child: const Icon(Icons.close, size: 18, color: Colors.black54),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Unidade de Medida: ${item.unit}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                              Text('Valor: R\$ ${item.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              if (_detectedOffers.isNotEmpty)
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _detectedOffers.length,
                    itemBuilder: (context, index) {
                      final item = _detectedOffers[index];
                      return Container(
                        width: 130,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.name} (R\$ ${item.price.toStringAsFixed(2)})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '- ${item.category}',
                              style: const TextStyle(fontSize: 9, color: Colors.grey),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              height: 24,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFBAE6FD),
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () => _addSingleItem(item),
                                icon: const Icon(Icons.add, size: 12, color: Color(0xFF0369A1)),
                                label: const Text('Adicionar', style: TextStyle(fontSize: 9, color: Color(0xFF0369A1))),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E6B5E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _importAll,
                  icon: const Icon(Icons.auto_awesome, color: Colors.greenAccent),
                  label: const Text(
                    'Importar Tudo',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0284C7),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.format_list_bulleted), label: 'Listas'),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer_outlined), label: 'Ofertas'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scanner'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}