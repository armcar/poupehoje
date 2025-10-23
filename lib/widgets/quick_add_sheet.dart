import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

Future<bool?> showQuickAddSheet(BuildContext context,
    {required String userId}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: const _QuickAddSheet(),
    ),
  );
}

class _QuickAddSheet extends StatefulWidget {
  const _QuickAddSheet();

  @override
  State<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<_QuickAddSheet> {
  final _valorController = TextEditingController();
  bool _isEntrada = false;
  String? _categoriaSelecionada;

  final _categorias = const [
    '💰 Vencimento',
    '💸 Pensão',
    '📦 Adiantamento',
    '🍽️ Alimentação',
    '🚗 Transportes',
    '🏠 Habitação',
    '🎉 Lazer',
    '💡 Serviços',
    '📱 Telecomunicações',
    '🛒 Supermercado',
    '💊 Saúde',
    '🧾 Outros',
  ];

  Future<void> _gravar() async {
    final texto = _valorController.text.trim();
    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduza um valor.')),
      );
      return;
    }

    final valor = double.tryParse(texto.replaceAll(',', '.'));
    if (valor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valor inválido.')),
      );
      return;
    }

    final categoria = _categoriaSelecionada ?? 'Outros';
    final data = DateTime.now();
    final valorFinal = _isEntrada ? valor.abs() : -valor.abs();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc('demo_user')
          .collection('transactions')
          .add({
        'description': 'Quick add',
        'amount': valorFinal,
        'category': categoria,
        'date': Timestamp.fromDate(data),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEntrada
                  ? 'Entrada registada (+${valorFinal.abs().toStringAsFixed(2)}€)'
                  : 'Despesa registada (-${valorFinal.abs().toStringAsFixed(2)}€)',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao gravar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao guardar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: cs.outlineVariant.withOpacity(.4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Text(
            'Lançamento rápido',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Valor
          TextField(
            controller: _valorController,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            decoration: const InputDecoration(
              labelText: 'Valor (€)',
              prefixIcon: Icon(Icons.euro_rounded),
            ),
          ),
          const SizedBox(height: 12),

          // Tipo (Entrada / Saída)
          ToggleButtons(
            borderRadius: BorderRadius.circular(12),
            isSelected: [_isEntrada, !_isEntrada],
            onPressed: (index) => setState(() => _isEntrada = index == 0),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Text('Entrada'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Text('Saída'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Categoria
          DropdownButtonFormField<String>(
            value: _categoriaSelecionada,
            decoration: const InputDecoration(
              labelText: 'Categoria',
              prefixIcon: Icon(Icons.category_rounded),
            ),
            items: _categorias
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (v) => setState(() => _categoriaSelecionada = v),
          ),

          const SizedBox(height: 22),

          ElevatedButton.icon(
            onPressed: _gravar,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Guardar'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
