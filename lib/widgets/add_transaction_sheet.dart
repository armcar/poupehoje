import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// Mostra o modal para adicionar uma nova transação.
/// Retorna `true` se for adicionada com sucesso.
Future<bool?> showAddTransactionSheet(
  BuildContext context, {
  required String userId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SafeArea(
      // ✅ evita ficar escondido atrás da barra inferior
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom,
        ),
        child: _AddTransactionSheet(userId: userId),
      ),
    ),
  );
}

class _AddTransactionSheet extends StatefulWidget {
  final String userId;
  const _AddTransactionSheet({required this.userId});

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  DateTime selectedDate = DateTime.now();
  String? categoria;

  // 🧩 Categorias uniformizadas com ícones
  final categorias = <Map<String, dynamic>>[
    {'nome': 'Vencimento', 'icon': Icons.payments_rounded},
    {'nome': 'Pensão', 'icon': Icons.account_balance_wallet_rounded},
    {'nome': 'Adiantamento', 'icon': Icons.trending_up_rounded},
    {'nome': 'Alimentação', 'icon': Icons.restaurant_rounded},
    {'nome': 'Transportes', 'icon': Icons.directions_bus_rounded},
    {'nome': 'Habitação', 'icon': Icons.home_rounded},
    {'nome': 'Saúde', 'icon': Icons.favorite_rounded},
    {'nome': 'Lazer', 'icon': Icons.local_activity_rounded},
    {'nome': 'Educação', 'icon': Icons.school_rounded},
    {'nome': 'Outros', 'icon': Icons.more_horiz_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brand = Theme.of(context).extension<BrandStyles>()!;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .25),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant.withValues(alpha: .4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Nova Transação',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),

              // 🔹 Descrição
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Descreve a transação'
                    : null,
              ),
              const SizedBox(height: 12),

              // 💶 Valor
              TextFormField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor (€)',
                  prefixIcon: Icon(Icons.euro_rounded),
                ),
                validator: (v) {
                  final parsed =
                      double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (parsed == null) return 'Introduz um número válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // 📂 Categoria com ícone
              DropdownButtonFormField<String>(
                value: categoria,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: categorias
                    .map<DropdownMenuItem<String>>(
                      (c) => DropdownMenuItem<String>(
                        value: c['nome'] as String,
                        child: Row(
                          children: [
                            Icon(c['icon'] as IconData, size: 18),
                            const SizedBox(width: 8),
                            Text(c['nome'] as String),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => categoria = val,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Seleciona uma categoria' : null,
              ),
              const SizedBox(height: 16),

              // 📅 Data
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Data: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        locale: const Locale('pt', 'PT'),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 💾 Botão Guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brand.primaryGradient.colors.first,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Guardar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final rawText = amountCtrl.text.trim().replaceAll(',', '.');
                    final rawValue = double.tryParse(rawText) ?? 0.0;
                    final absValue = rawValue.abs();

                    final entradasCats = {
                      'Vencimento',
                      'Pensão',
                      'Adiantamento'
                    };
                    final isEntrada = entradasCats.contains(categoria);
                    final finalAmount = isEntrada ? absValue : -absValue;

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .collection('transactions')
                        .add({
                      'title': titleCtrl.text.trim(),
                      'amount': finalAmount,
                      'date': Timestamp.fromDate(selectedDate),
                      'category': categoria ?? 'Outros',
                    });

                    if (context.mounted) Navigator.pop(context, true);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
