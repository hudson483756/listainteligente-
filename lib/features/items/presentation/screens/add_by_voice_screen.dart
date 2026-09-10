import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lista_inteligente/services/groq_voice_service.dart';

class AddByVoiceScreen extends StatefulWidget {
  final String? listId;

  const AddByVoiceScreen({super.key, this.listId});

  @override
  State<AddByVoiceScreen> createState() => _AddByVoiceScreenState();
}

class _AddByVoiceScreenState extends State<AddByVoiceScreen> {
  late stt.SpeechToText _speech;

  bool _isListening = false;
  bool _isProcessing = false;
  String _transcribedText = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<bool> _hasInternet() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }
      final result = await InternetAddress.lookup('api.groq.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          if (_isListening) {
            _stopAndProcess();
          }
        }
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _transcribedText = '';
      });

      _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
        ),
        onResult: (val) {
          setState(() {
            _transcribedText = val.recognizedWords;
          });
        },
      );
    } else {
      _showSnackBar('Microfone não disponível ou permissão negada.');
    }
  }

  void _stopAndProcess() async {
    await _speech.stop();
    setState(() => _isListening = false);

    if (_transcribedText.trim().isNotEmpty) {
      _processVoiceInput(_transcribedText.trim());
    }
  }

  Future<void> _processVoiceInput(String text) async {
    setState(() => _isProcessing = true);

    String name = text;
    double quantity = 1.0;
    String unit = 'un';
    double price = 0.0;
    String category = 'Geral';
    bool isAiProcessed = false;

    final isOnline = await _hasInternet();

    if (isOnline) {
      try {
        final ExtractedVoiceItem? result = await GroqVoiceService.parseSpokenText(text);
        if (result != null) {
          name = result.name;
          quantity = result.quantity;
          unit = result.unit;
          price = result.price;
          category = result.category;
          isAiProcessed = true;
        }
      } catch (e) {
        debugPrint('Erro na IA: $e');
      }
    }

    if (!isAiProcessed) {
      final qtyMatch = RegExp(r'^(\d+[\.,]?\d*)\s*(kg|g|ml|l|un|caixa|pacote)?\s+(?:de\s+)?(.*)', caseSensitive: false).firstMatch(text);
      if (qtyMatch != null) {
        quantity = double.tryParse(qtyMatch.group(1)!.replaceAll(',', '.')) ?? 1.0;
        if (qtyMatch.group(2) != null) unit = qtyMatch.group(2)!.toLowerCase();
        name = qtyMatch.group(3) ?? text;
      }
    }

    if (mounted) {
      setState(() => _isProcessing = false);

      _showConfirmationModal(
        spokenText: text,
        extractedName: name,
        extractedQuantity: quantity,
        extractedUnit: unit,
        extractedPrice: price,
        extractedCategory: category,
        usedAi: isAiProcessed,
      );
    }
  }

  void _showConfirmationModal({
    required String spokenText,
    required String extractedName,
    required double extractedQuantity,
    required String extractedUnit,
    required double extractedPrice,
    required String extractedCategory,
    required bool usedAi,
  }) async {
    final nameController = TextEditingController(text: extractedName);
    final qtyController = TextEditingController(text: extractedQuantity.toString());
    final priceController = TextEditingController(text: extractedPrice.toStringAsFixed(2));

    final snapshot = await FirebaseFirestore.instance.collection('listas').get();
    final userLists = snapshot.docs.map((doc) => {'id': doc.id, 'name': (doc.data()['nome'] ?? 'Sem nome').toString()}).toList();

    String? selectedListId = widget.listId ?? (userLists.isNotEmpty ? userLists.first['id'] : null);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Confirmar Cadastro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Chip(
                        avatar: Icon(usedAi ? Icons.auto_awesome : Icons.wifi_off, size: 16, color: usedAi ? Colors.blue : Colors.orange),
                        label: Text(usedAi ? 'IA Processado' : 'Modo Offline', style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedListId,
                          decoration: const InputDecoration(labelText: 'Lista de Destino', border: OutlineInputBorder()),
                          items: userLists.map((l) => DropdownMenuItem(value: l['id'], child: Text(l['name']!))).toList(),
                          onChanged: (val) => setModalState(() => selectedListId = val),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                        onPressed: () async {
                          final newController = TextEditingController();
                          final newId = await showDialog<String>(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              title: const Text('Nova Lista'),
                              content: TextField(controller: newController, decoration: const InputDecoration(labelText: 'Nome')),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancelar')),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (newController.text.trim().isNotEmpty) {
                                      final doc = await FirebaseFirestore.instance.collection('listas').add({
                                        'nome': newController.text.trim(),
                                        'createdAt': FieldValue.serverTimestamp(),
                                      });
                                      if (dCtx.mounted) Navigator.pop(dCtx, doc.id);
                                    }
                                  },
                                  child: const Text('Criar'),
                                )
                              ],
                            ),
                          );
                          if (newId != null) {
                            final freshSnap = await FirebaseFirestore.instance.collection('listas').get();
                            userLists.clear();
                            userLists.addAll(freshSnap.docs.map((d) => {'id': d.id, 'name': (d.data()['nome'] ?? 'Sem nome').toString()}));
                            setModalState(() => selectedListId = newId);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nome do Produto', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Qtd ($extractedUnit)', border: const OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Preço Estimado (R\$)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(modalContext),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C4A5E)),
                          onPressed: () async {
                            final String finalName = nameController.text.trim();
                            final double finalQty = double.tryParse(qtyController.text) ?? extractedQuantity;
                            final double finalPrice = double.tryParse(priceController.text.replaceAll(',', '.')) ?? extractedPrice;

                            if (finalName.isEmpty || selectedListId == null) return;

                            final navigator = Navigator.of(context);
                            final modalNavigator = Navigator.of(modalContext);

                            await FirebaseFirestore.instance
                                .collection('listas')
                                .doc(selectedListId)
                                .collection('itens')
                                .add({
                              'name': finalName,
                              'quantity': finalQty,
                              'unit': extractedUnit,
                              'price': finalPrice,
                              'category': extractedCategory,
                              'isPurchased': false,
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            if (!mounted) return;
                            modalNavigator.pop();
                            navigator.pop(true);
                          },
                          child: const Text('Salvar Item', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar por Voz')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _isListening ? _stopAndProcess : _startListening,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: _isListening ? Colors.red : const Color(0xFF2C4A5E),
                child: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white, size: 48),
              ),
            ),
            const SizedBox(height: 20),
            Text(_isListening ? 'Escutando...' : 'Toque para falar', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_isProcessing) const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}