import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Um chip elegante que mostra a data de hoje.
/// Usa o [ColorScheme] atual do tema para adaptar cor.
class DateChip extends StatelessWidget {
  const DateChip({super.key});

  String _todayLabel() {
    final now = DateTime.now();
    final dow = DateFormat('EEEE', 'pt_PT').format(now);
    final date = DateFormat('dd/MM/yyyy', 'pt_PT').format(now);
    final niceDow = '${dow[0].toUpperCase()}${dow.substring(1)}';
    return '$niceDow, $date';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            _todayLabel(),
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
