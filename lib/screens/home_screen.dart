import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../services/tips_service.dart';
import '../widgets/add_transaction_sheet.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double entradas = 0;
  double saidas = 0;
  double saldo = 0;
  String dicaAtual = '💡 A carregar dica de poupança...';

  @override
  void initState() {
    super.initState();
    _carregarResumo();
    _carregarDicaAleatoria();
  }

  Future<void> _carregarDicaAleatoria() async {
    final dica = await TipsService.instance.getDicaAleatoria();
    if (!mounted) return;
    setState(() => dicaAtual = dica);
  }

  Future<void> _carregarResumo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .get();

      double totalEntradas = 0;
      double totalSaidas = 0;

      for (var doc in snapshot.docs) {
        final valor = (doc['amount'] as num? ?? 0).toDouble();
        if (valor >= 0) {
          totalEntradas += valor;
        } else {
          totalSaidas += valor.abs();
        }
      }

      if (!mounted) return;
      setState(() {
        entradas = totalEntradas;
        saidas = totalSaidas;
        saldo = totalEntradas - totalSaidas;
      });
    } catch (e) {
      debugPrint('Erro ao carregar resumo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brand = Theme.of(context).extension<BrandStyles>()!;
    final hoje = DateFormat('EEE, d MMM yyyy', 'pt_PT').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: () async {
        await _carregarResumo();
        TipsService.instance.limparCache();
        await _carregarDicaAleatoria();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, ${FirebaseAuth.instance.currentUser?.displayName ?? "utilizador"} 👋',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bem-vindo de volta ao Poupe Hoje — $hoje',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            // 💰 Saldo atual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                gradient: brand.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [brand.glowShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo atual',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${saldo.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 💬 Dica de poupança
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                gradient: brand.primarySoftGradient,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: cs.primary.withValues(alpha: .12),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.lightbulb_rounded,
                        color: cs.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dicaAtual,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ⚡ Ações rápidas
            Text(
              'Ações rápidas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionCard(
                  icon: Icons.add_circle_rounded,
                  label: 'Nova transação',
                  color: cs.primary,
                  onTap: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;

                    final result = await showAddTransactionSheet(
                      context,
                      userId: user.uid,
                    );
                    if (result == true) await _carregarResumo();
                  },
                ),
                _ActionCard(
                  icon: Icons.bar_chart_rounded,
                  label: 'Ver dashboard',
                  color: Colors.greenAccent.shade400,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DashboardScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 📊 Resumo rápido
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ResumoCard(
                    label: 'Entradas', valor: entradas, color: Colors.green),
                _ResumoCard(
                    label: 'Saídas', valor: saidas, color: Colors.redAccent),
                _ResumoCard(label: 'Saldo', valor: saldo, color: cs.primary),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// 🔹 Cartão de ação
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        width: 160,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 Cartão de resumo
class _ResumoCard extends StatelessWidget {
  final String label;
  final double valor;
  final Color color;

  const _ResumoCard({
    required this.label,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${valor.toStringAsFixed(2)} €',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
