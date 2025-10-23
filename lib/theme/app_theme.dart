import 'package:flutter/material.dart';

/// --- Extensão com estilos de marca (gradientes, glow, etc.) ---
@immutable
class BrandStyles extends ThemeExtension<BrandStyles> {
  final LinearGradient primaryGradient; // azul -> roxo (forte)
  final LinearGradient surfaceGradient; // fundo suave
  final LinearGradient
      primarySoftGradient; // azul/roxo muito suave (chips/pills)
  final BoxShadow glowShadow; // glow/cozy

  const BrandStyles({
    required this.primaryGradient,
    required this.surfaceGradient,
    required this.primarySoftGradient,
    required this.glowShadow,
  });

  @override
  BrandStyles copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? surfaceGradient,
    LinearGradient? primarySoftGradient,
    BoxShadow? glowShadow,
  }) {
    return BrandStyles(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      surfaceGradient: surfaceGradient ?? this.surfaceGradient,
      primarySoftGradient: primarySoftGradient ?? this.primarySoftGradient,
      glowShadow: glowShadow ?? this.glowShadow,
    );
  }

  @override
  BrandStyles lerp(ThemeExtension<BrandStyles>? other, double t) {
    if (other is! BrandStyles) return this;
    return other;
  }
}

/// --- Tema ---
class AppTheme {
  AppTheme._();

  // Paleta base
  static const _brandBlue = Color(0xFF3B82F6);
  static const _brandPurple = Color(0xFF8B5CF6);

  // Esquemas base (Material You a partir de seed)
  static final _lightScheme = ColorScheme.fromSeed(
    seedColor: _brandPurple,
    brightness: Brightness.light,
    primary: _brandPurple,
    secondary: _brandBlue,
  );

  static final _darkScheme = ColorScheme.fromSeed(
    seedColor: _brandPurple,
    brightness: Brightness.dark,
    primary: _brandPurple,
    secondary: _brandBlue,
  );

  // Getters públicos
  static ThemeData get light =>
      _build(_lightScheme, isDark: false, oled: false);
  static ThemeData get dark => _build(_darkScheme, isDark: true, oled: false);
  static ThemeData get darkOled =>
      _build(_darkScheme, isDark: true, oled: true);

  static ThemeData _build(
    ColorScheme scheme, {
    required bool isDark,
    required bool oled,
  }) {
    final surface = isDark
        ? (oled ? const Color(0xFF000000) : const Color(0xFF0B1220))
        : const Color(0xFFF5F7FF);

    final cardColor = isDark
        ? (oled ? const Color(0xFF0A0F1A) : const Color(0xFF1E293B))
        : Colors.white;

    final fillColor = isDark
        ? (oled ? const Color(0xFF0A0F1A) : const Color(0xFF101826))
        : Colors.white;

    final brand = BrandStyles(
      primaryGradient: const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [_brandBlue, _brandPurple],
      ),
      surfaceGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [surface, isDark ? surface.withOpacity(.98) : surface]
            : const [Color(0xFFF4F5FF), Color(0xFFF7F2FF)],
      ),
      primarySoftGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scheme.primary.withOpacity(.08),
          scheme.primary.withOpacity(.12),
        ],
      ),
      glowShadow: BoxShadow(
        color: _brandPurple.withOpacity(isDark ? .45 : .28),
        blurRadius: 18,
        offset: const Offset(0, 12),
      ),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      // Tipografia: um pouco mais “bold”
      textTheme: isDark
          ? Typography.whiteMountainView.copyWith(
              titleLarge: const TextStyle(fontWeight: FontWeight.w800),
              bodyMedium: const TextStyle(height: 1.2),
            )
          : Typography.blackMountainView.copyWith(
              titleLarge: const TextStyle(fontWeight: FontWeight.w800),
              bodyMedium: const TextStyle(height: 1.2),
            ),
      extensions: <ThemeExtension<dynamic>>[brand],
    );

    return base.copyWith(
      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),

      // Cards
      // ===== Cards =====
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        shadowColor: Colors.black.withOpacity(isDark ? .40 : .08),
      ),

      // ===== Dialogs =====
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withOpacity(.30),
        thickness: 1,
        space: 24,
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: Colors.white,
          backgroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary.withOpacity(.35)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        ),
      ),

      // Chips
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: scheme.outlineVariant.withOpacity(.40)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        backgroundColor: isDark
            ? (oled ? const Color(0xFF0A0F1A) : const Color(0xFF111827))
            : scheme.primary.withOpacity(.08),
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return sel ? scheme.primary : scheme.surfaceContainerHighest;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return sel
              ? scheme.primary.withOpacity(.35)
              : scheme.outlineVariant.withOpacity(.50);
        }),
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white),
      ),

      // Progress indicators
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withOpacity(.15),
      ),

      // Icon & ListTile
      iconTheme: IconThemeData(color: scheme.onSurface),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        backgroundColor:
            isDark ? const Color(0xFF1F2937) : const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // NavigationBar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? surface : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withOpacity(.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return TextStyle(
            fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
            color: sel ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
    );
  }
}
