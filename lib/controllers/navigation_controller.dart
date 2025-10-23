import 'package:flutter/material.dart';

/// Controla o índice ativo da NavigationBar.
/// Qualquer ecrã pode chamar NavigationController.instance.goTo(index)
/// para navegar sem recriar o RootScreen.
class NavigationController {
  static final NavigationController instance = NavigationController._();

  NavigationController._();

  /// Índice atual do separador ativo.
  final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);

  /// Muda o separador.
  void goTo(int index) => currentIndex.value = index;
}
