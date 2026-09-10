import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lista_inteligente/features/items/presentation/screens/add_by_voice_screen.dart';
import 'package:lista_inteligente/features/items/presentation/screens/barcode_scanner_screen.dart';
import 'package:lista_inteligente/services/groq_vision_service.dart';

class AddItemScreen extends StatefulWidget {
  final String? listId;
  final Map<String, dynamic>? itemToEdit;

  const AddItemScreen({
    super.key,
    this.listId,
    this.itemToEdit,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;
  late TextEditingController _supermarketController;

  String? _selectedListId;
  String _selectedUnit = 'un';
  bool _isSaving = false;
  bool _isLoadingLists = true;

  List<Map<String, String>> _userLists = [];
  final List<String> _unitOptions = ['un', 'kg', 'g', 'ml', 'L'];

  @override
  void initState() {
    super.initState();
    _selectedListId = widget.listId;

    final item = widget.itemToEdit;
    final String initialName = item?['name'] ?? item?['nome'] ?? '';
    final String initialQuantity = (item?['quantity'] ?? item?['quantidade'])?.toString() ?? '1';
    final String initialPrice = (item?['price'] ?? item?['preco'])?.toString() ?? '';
    final String initialCategory = item?['category'] ?? item?['categoria'] ?? '';
    final String initialSupermarket = item?['supermarket'] ?? item?['supermercado'] ?? '';
    final String? unit = item?['unit'] ?? item?['unidade'];

    _nameController = TextEditingController(text: initialName);
    _quantityController = TextEditingController(text: initialQuantity);
    _priceController = TextEditingController(text: initialPrice);
    _categoryController = TextEditingController(text: initialCategory);
    _supermarketController = TextEditingController(text: initialSupermarket);

    if (unit != null && _unitOptions.contains(unit)) {
      _selectedUnit = unit;
    }

    _fetchUserLists();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _supermarketController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserLists() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('listas').get();
      final loadedLists = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': (data['nome'] ?? data['name'] ?? 'Sem nome').toString(),
        };
      }).toList();

      if (mounted) {
        setState(() {
          _userLists = loadedLists;
          _isLoadingLists = false;

          if (_selectedListId == null && _userLists.isNotEmpty) {
            _selectedListId = _userLists.first['id'];
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingLists = false);
      }
    }
  }

  Future<void> _createNewListDialog() async {
    final nameController = TextEditingController();
    final newId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Criar Nova Lista'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nome da Lista',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final docRef = await FirebaseFirestore.instance.collection('listas').add({
                  'nome': name,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx, docRef.id);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (newId != null) {
      await _fetchUserLists();
      setState(() {
        _selectedListId = newId;
      });
    }
  }

  void _openVoiceScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddByVoiceScreen(listId: _selectedListId),
      ),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _openBarcodeScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _nameController.text = result['name'] ?? '';
        _categoryController.text = result['category'] ?? '';
        if (result['price'] != null) {
          _priceController.text = result['price'].toString();
        }
      });
    }
  }

  void _openPhotoRecognition() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Analisando produto com IA...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final items = await GroqVisionService.analyzeOfferImage(File(image.path));
      if (!mounted) return;
      Navigator.pop(context);

      if (items.isNotEmpty) {
        final firstItem = items.first;
        setState(() {
          _nameController.text = firstItem.name;
          _priceController.text = firstItem.price.toStringAsFixed(2);
          _categoryController.text = firstItem.category;
          if (_unitOptions.contains(firstItem.unit)) {
            _selectedUnit = firstItem.unit;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum produto identificado na foto.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao analisar imagem: $e')),
      );
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedListId == null || _selectedListId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione ou crie uma lista.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final String name = _nameController.text.trim();
      final double quantity = double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 1.0;
      final double price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0;
      final String category = _categoryController.text.trim();
      final String supermarket = _supermarketController.text.trim();

      final itemsRef = FirebaseFirestore.instance
          .collection('listas')
          .doc(_selectedListId)
          .collection('itens');

      final itemData = {
        'name': name,
        'quantity': quantity,
        'unit': _selectedUnit,
        'price': price,
        'category': category.isEmpty ? 'Geral' : category,
        'supermarket': supermarket,
        'isPurchased': widget.itemToEdit?['isPurchased'] ?? false,
      };

      if (widget.itemToEdit != null && widget.itemToEdit!['id'] != null) {
        final String docId = widget.itemToEdit!['id'].toString();
        await itemsRef.doc(docId).update({
          ...itemData,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await itemsRef.add({
          ...itemData,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar item: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.itemToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Item' : 'Novo Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isLoadingLists) const LinearProgressIndicator(),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedListId,
                      decoration: const InputDecoration(
                        labelText: 'Lista de Destino',
                        border: OutlineInputBorder(),
                      ),
                      items: _userLists.map((list) {
                        return DropdownMenuItem<String>(
                          value: list['id'],
                          child: Text(list['name'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedListId = val);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                    tooltip: 'Criar Nova Lista',
                    onPressed: _createNewListDialog,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openVoiceScreen,
                      icon: const Icon(Icons.mic, size: 18),
                      label: const Text('Voz'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openBarcodeScanner,
                      icon: const Icon(Icons.qr_code, size: 18),
                      label: const Text('Código'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openPhotoRecognition,
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Foto'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome do Produto*', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Quantidade', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: const InputDecoration(labelText: 'Unidade', border: OutlineInputBorder()),
                      items: _unitOptions.map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUnit = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Preço Estimado (R\$)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveItem,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isSaving ? const CircularProgressIndicator() : Text(isEditing ? 'Atualizar Item' : 'Salvar Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}