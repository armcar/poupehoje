import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/add_transaction_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _firestore = FirebaseFirestore.instance;
  late String _userId;

  late DateTime _startDate;
  late DateTime _endDate;

  String? _categoriaSelecionada; // null = Todos

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    _userId = FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';
  }

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandStyles>()!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: brand.surfaceGradient),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .doc(_userId)
              .collection('transactions')
              .where('date', isGreaterThanOrEqualTo: _startDate)
              .where('date', isLessThanOrEqualTo: _endDate)
              .orderBy('date', descending: true)
              .snapshots(includeMetadataChanges: true), // 👈 mais reativo
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) return const SizedBox.shrink();

            // Tudo do período selecionado
            final allPeriod = snapshot.data!.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return {
                'title': (data['title'] ?? '') as String,
                'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
                'date': (data['date'] as Timestamp).toDate(),
                'category': (data['category'] ?? 'Outros') as String,
                'icon': (data['icon'] ?? '') as String, // opcional emoji
              };
            }).toList();

            // Categorias únicas no período (ordenadas por frequência)
            final Map<String, int> freq = {};
            final Map<String, String> catEmoji = {};
            for (final t in allPeriod) {
              final c = (t['category'] as String).trim();
              if (c.isEmpty) continue;
              freq[c] = (freq[c] ?? 0) + 1;
              final emoji = (t['icon'] as String?) ?? '';
              if (emoji.isNotEmpty && !catEmoji.containsKey(c)) {
                catEmoji[c] = emoji;
              }
            }
            final categoriasOrdenadas = freq.keys.toList()
              ..sort((a, b) => freq[b]!.compareTo(freq[a]!));

            // Aplica filtro (se existir)
            final filtered = _categoriaSelecionada == null
                ? allPeriod
                : allPeriod
                    .where((t) =>
                        (t['category'] as String).toLowerCase() ==
                        _categoriaSelecionada!.toLowerCase())
                    .toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PeriodoSelector(
                  startDate: _startDate,
                  endDate: _endDate,
                  onChanged: (start, end) {
                    setState(() {
                      _startDate = DateTime(start.year, start.month, start.day);
                      _endDate =
                          DateTime(end.year, end.month, end.day, 23, 59, 59);
                      // mantém filtro ativo
                    });
                  },
                ),

                const SizedBox(height: 12),

                // 🔎 Filtro de Categorias (chips)
                _FiltroCategorias(
                  categorias: categoriasOrdenadas,
                  emojiPorCategoria: catEmoji,
                  categoriaSelecionada: _categoriaSelecionada,
                  onSelecionar: (c) {
                    setState(() => _categoriaSelecionada = c);
                  },
                ),

                const SizedBox(height: 12),

                // Resumo do período (respeita o filtro)
                _ResumoPeriodo(transactions: filtered),

                const SizedBox(height: 16),

                // Gráfico de barras (respeita o filtro)
                _GraficoMovimentos(transactions: filtered),

                const SizedBox(height: 16),

                // Pie de categorias (respeita o filtro, mas faz sentido só quando Todos ou múltiplas cats)
                _GraficoCategorias(transactions: filtered),

                const SizedBox(height: 16),

                // Últimos movimentos (respeita o filtro)
                _UltimosMovimentos(transactions: filtered),

                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;

          final result =
              await showAddTransactionSheet(context, userId: user.uid);
          if (result == true && context.mounted) {
            // Feedback + rebuild leve (stream também vai atualizar)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Transação guardada com sucesso'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
            setState(() {}); // reforça refresh imediato da UI
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Adicionar', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// ========================
// SELECTOR DE PERÍODO
// ========================
class _PeriodoSelector extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final void Function(DateTime, DateTime) onChanged;

  const _PeriodoSelector({
    required this.startDate,
    required this.endDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: Navigator.of(context)
                        .context, // 👈 usa o contexto raiz do MaterialApp
                    initialDate: endDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    locale: const Locale('pt', 'PT'),
                  );
                  if (picked != null) onChanged(picked, endDate);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text('De ${DateFormat('dd/MM/yyyy').format(startDate)}'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward_rounded, color: cs.primary),
            ),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    locale: const Locale('pt', 'PT'),
                  );
                  if (picked != null) {
                    onChanged(
                      startDate,
                      DateTime(
                          picked.year, picked.month, picked.day, 23, 59, 59),
                    );
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text('Até ${DateFormat('dd/MM/yyyy').format(endDate)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================
// FILTRO RÁPIDO DE CATEGORIAS
// ========================
class _FiltroCategorias extends StatelessWidget {
  final List<String> categorias;
  final Map<String, String> emojiPorCategoria; // cat -> emoji
  final String? categoriaSelecionada;
  final ValueChanged<String?> onSelecionar;

  const _FiltroCategorias({
    required this.categorias,
    required this.emojiPorCategoria,
    required this.categoriaSelecionada,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (categorias.isEmpty) {
      return const SizedBox.shrink();
    }

    // Mostra no máx. 10 chips (os mais frequentes)
    final top = categorias.take(10).toList();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Todos'),
              selected: categoriaSelecionada == null,
              onSelected: (_) => onSelecionar(null),
              selectedColor: cs.primary,
              checkmarkColor: cs.onPrimary,
              labelStyle: TextStyle(
                color:
                    categoriaSelecionada == null ? cs.onPrimary : cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            for (final c in top)
              FilterChip(
                label: Text(
                  '${emojiPorCategoria[c] ?? ''}${emojiPorCategoria[c] != null ? ' ' : ''}${_titleCase(c)}',
                ),
                selected:
                    categoriaSelecionada?.toLowerCase() == c.toLowerCase(),
                onSelected: (_) => onSelecionar(c),
                selectedColor: cs.primary,
                checkmarkColor: cs.onPrimary,
                labelStyle: TextStyle(
                  color: categoriaSelecionada?.toLowerCase() == c.toLowerCase()
                      ? cs.onPrimary
                      : cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }
}

// ========================
// RESUMO DO PERÍODO (respeita o filtro)
// ========================
class _ResumoPeriodo extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  const _ResumoPeriodo({required this.transactions});

  @override
  Widget build(BuildContext context) {
    double entradas = 0;
    double saidas = 0;

    for (final t in transactions) {
      final valor = t['amount'] as double;
      if (valor >= 0) {
        entradas += valor;
      } else {
        saidas += valor.abs();
      }
    }

    final saldo = entradas - saidas;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ResumoItem(
              icon: Icons.arrow_downward_rounded,
              label: 'Saídas',
              value: saidas,
              color: Colors.redAccent,
            ),
            _ResumoItem(
              icon: Icons.arrow_upward_rounded,
              label: 'Entradas',
              value: entradas,
              color: Colors.greenAccent.shade400,
            ),
            _ResumoItem(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Saldo',
              value: saldo,
              color: saldo >= 0 ? Colors.blueAccent : Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;

  const _ResumoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        Text(
          '€ ${value.toStringAsFixed(2)}',
          style: TextStyle(fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

// ========================
// GRÁFICO DE MOVIMENTOS (respeita o filtro)
// ========================
class _GraficoMovimentos extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  const _GraficoMovimentos({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Sem dados neste período / filtro')),
      );
    }

    // ano-mês -> {entradas, saidas, saldo}
    final Map<String, Map<String, double>> monthly = {};

    for (final t in transactions) {
      final date = t['date'] as DateTime;
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final valor = t['amount'] as double;

      monthly.putIfAbsent(key, () => {'entradas': 0, 'saidas': 0, 'saldo': 0});
      if (valor >= 0) {
        monthly[key]!['entradas'] = (monthly[key]!['entradas'] ?? 0) + valor;
      } else {
        monthly[key]!['saidas'] = (monthly[key]!['saidas'] ?? 0) + valor.abs();
      }
      monthly[key]!['saldo'] =
          (monthly[key]!['entradas'] ?? 0) - (monthly[key]!['saidas'] ?? 0);
    }

    final sortedKeys = monthly.keys.toList()..sort();
    final barGroups = List.generate(sortedKeys.length, (i) {
      final m = monthly[sortedKeys[i]]!;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
              toY: m['entradas']!, color: Colors.greenAccent, width: 10),
          BarChartRodData(
              toY: m['saidas']!, color: Colors.redAccent, width: 10),
          BarChartRodData(
              toY: m['saldo']!, color: Colors.blueAccent, width: 10),
        ],
        barsSpace: 4,
      );
    });

    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez'
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Movimentos no período',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= sortedKeys.length) {
                            return const SizedBox.shrink();
                          }
                          final key = sortedKeys[index];
                          final month = int.parse(key.split('-')[1]);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              months[month - 1],
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================
// GRÁFICO DE CATEGORIAS (respeita o filtro)
// ========================
class _GraficoCategorias extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  const _GraficoCategorias({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final despesas =
        transactions.where((t) => (t['amount'] as double) < 0).toList();
    if (despesas.isEmpty) {
      return const SizedBox(
          height: 200,
          child: Center(child: Text('Sem despesas neste período / filtro')));
    }

    final Map<String, double> totais = {};
    for (final t in despesas) {
      final cat = t['category'] as String? ?? 'Outros';
      final v = (t['amount'] as double).abs();
      totais[cat] = (totais[cat] ?? 0) + v;
    }

    final totalDesp = totais.values.fold(0.0, (a, b) => a + b);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Distribuição de Despesas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: totais.entries.map((e) {
                    final color = Colors
                        .primaries[e.key.hashCode % Colors.primaries.length];
                    final percent = (e.value / totalDesp) * 100;
                    return PieChartSectionData(
                      color: color,
                      value: e.value,
                      title: '${percent.toStringAsFixed(1)}%',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: totais.keys.map((k) {
                final color =
                    Colors.primaries[k.hashCode % Colors.primaries.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, color: color),
                    const SizedBox(width: 6),
                    Text(_titleCase(k),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }
}

// ========================
// ÚLTIMOS MOVIMENTOS (com Ver Mais) — respeita o filtro
// ========================
class _UltimosMovimentos extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;
  const _UltimosMovimentos({required this.transactions});

  @override
  State<_UltimosMovimentos> createState() => _UltimosMovimentosState();
}

class _UltimosMovimentosState extends State<_UltimosMovimentos> {
  bool verMais = false;

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return const Card(
        elevation: 3,
        margin: EdgeInsets.zero,
        child: SizedBox(
          height: 120,
          child:
              Center(child: Text('Sem movimentos nesta categoria / período')),
        ),
      );
    }

    final sorted = [
      ...widget.transactions
    ]..sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    final mostrar = verMais ? sorted : sorted.take(5).toList();
    final temMais = sorted.length > 5;
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 6),
              child: Text('Últimos Movimentos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ...mostrar.map((t) {
              final valor = t['amount'] as double;
              final categoria = t['category'] as String? ?? 'Outros';
              final data = DateFormat('dd/MM').format(t['date'] as DateTime);
              return ListTile(
                leading: Icon(
                  valor >= 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: valor >= 0
                      ? Colors.greenAccent.shade400
                      : Colors.redAccent,
                ),
                title: Text(t['title'],
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${_titleCase(categoria)}  •  $data'),
                trailing: Text(
                  '${valor >= 0 ? '+' : '-'}€${valor.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    color: valor >= 0 ? Colors.greenAccent.shade400 : cs.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }),
            if (temMais) ...[
              const SizedBox(height: 6),
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => verMais = !verMais),
                  icon: Icon(
                    verMais ? Icons.expand_less : Icons.expand_more,
                    color: cs.primary,
                  ),
                  label: Text(
                    verMais ? 'Mostrar menos' : 'Ver mais registos',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }
}
