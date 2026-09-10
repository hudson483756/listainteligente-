import 'package:flutter/material.dart';

Widget buildSettingsTabContent(BuildContext context, Color customGreen, double monthlyBudget, Function(double) onSave) {
  final controller = TextEditingController(text: monthlyBudget.toStringAsFixed(2));

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Configurações de Orçamento', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161A22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Teto do Orçamento Mensal', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: 'R\$ ',
                  prefixStyle: TextStyle(color: customGreen, fontSize: 18),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: customGreen)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: customGreen),
                  onPressed: () {
                    final val = double.tryParse(controller.text) ?? monthlyBudget;
                    onSave(val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Teto de orçamento atualizado!')),
                    );
                  },
                  child: const Text('Salvar Novo Teto', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ],
    ),
  );
}