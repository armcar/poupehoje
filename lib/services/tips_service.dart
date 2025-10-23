import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Serviço responsável por obter e guardar em cache as dicas de poupança.
///
/// Utilização típica:
/// ```dart
/// final dica = await TipsService.instance.getDicaAleatoria();
/// ```
class TipsService {
  TipsService._();

  static final TipsService instance = TipsService._();

  String? _cachedTip; // 🧠 cache em memória

  /// Retorna uma dica aleatória de poupança (com cache temporária).
  Future<String> getDicaAleatoria() async {
    // se já temos uma dica em cache, devolvemos logo
    if (_cachedTip != null) return _cachedTip!;

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('tips').get();

      if (snapshot.docs.isEmpty) {
        _cachedTip = '💡 Dica: comece a poupar hoje!';
      } else {
        final docs = snapshot.docs;
        final randomIndex = Random().nextInt(docs.length);
        final data = docs[randomIndex].data();

        final icon = data['icon'] ?? '💡';
        final text = data['text'] ?? 'Dica: reveja o seu orçamento.';
        _cachedTip = "$icon $text";
      }
    } catch (e) {
      debugPrint('❌ Erro ao obter dica: $e');
      _cachedTip = '💡 Dica: reveja o seu orçamento e defina metas semanais.';
    }

    return _cachedTip!;
  }

  /// Limpa a cache (ex: quando o utilizador faz pull-to-refresh)
  void limparCache() {
    _cachedTip = null;
  }
}
