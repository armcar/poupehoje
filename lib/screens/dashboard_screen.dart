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
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) return const SizedBox.shrink();

            final transactions = snapshot.data!.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return {
                'title': (data['title'] ?? '') as String,
                'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
                'date': (data['date'] as Timestamp).toDate(),
                'category': (data['category'] ?? 'Outros') as String,
              };
            }).toList();

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
                    });
                  },
                ),
                const SizedBox(height: 12),
                _ResumoPeriodo(transactions: transactions),
                const SizedBox(height: 16),
                _GraficoMovimentos(transactions: transactions),
                const SizedBox(height: 16),
                _GraficoCategorias(transactions: transactions),
                const SizedBox(height: 16),
                _UltimosMovimentos(transactions: transactions),
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
          if (result == true) {
            setState(() {}); // 🔄 atualiza automaticamente
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
                    context: context,
                    initialDate: startDate,
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
                            picked.year, picked.month, picked.day, 23, 59, 59));
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
// RESUMO DO PERÍODO
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
// GRÁFICO DE MOVIMENTOS
// ========================
class _GraficoMovimentos extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  const _GraficoMovimentos({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Sem dados no período')),
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
// GRÁFICO DE CATEGORIAS
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
          child: Center(child: Text('Sem despesas neste período')));
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
                    Text(k,
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
}

// ========================
// ÚLTIMOS MOVIMENTOS
// ========================
class _UltimosMovimentos extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  const _UltimosMovimentos({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) return const SizedBox.shrink();

    final sorted = [
      ...transactions
    ]..sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

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
            ...sorted.take(5).map((t) {
              final valor = t['amount'] as double;
              final categoria = t['category'] as String? ?? 'Outros';
              final data = DateFormat('dd/MM').format(t['date'] as DateTime);
              final cs = Theme.of(context).colorScheme;
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
                subtitle: Text('$categoria  •  $data'),
                trailing: Text(
                  '${valor >= 0 ? '+' : '-'}€${valor.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    color: valor >= 0 ? Colors.greenAccent.shade400 : cs.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
