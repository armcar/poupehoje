import 'package:flutter/material.dart';

class ThemeController {
  // Instância singleton
  static final ThemeController instance = ThemeController._();
  ThemeController._();

  // Estado do modo de tema
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  // Alternar entre claro e escuro
  void toggleTheme() {
    final current = themeMode.value;
    if (current == ThemeMode.dark) {
      themeMode.value = ThemeMode.light;
    } else {
      themeMode.value = ThemeMode.dark;
    }
  }

  // Definir modo manualmente
  void setTheme(ThemeMode mode) {
    themeMode.value = mode;
  }
}
