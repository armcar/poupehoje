import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../theme/theme_controller.dart'; // ✅ usa o teu controller de tema (ValueNotifier)

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onMenuTap;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onMenuTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brand = Theme.of(context).extension<BrandStyles>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hoje = DateFormat('EEE, d MMM', 'pt_PT').format(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        gradient: brand.surfaceGradient,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              // ☰ Botão do menu (Drawer)
              if (onMenuTap != null)
                IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  color: cs.onSurface,
                  onPressed: onMenuTap,
                ),

              // 🐷 Logo + título
              Expanded(
                child: Row(
                  children: [
                    // LOGO — substitui o caminho conforme o teu ficheiro real
                    Image.asset(
                      'assets/icons/icon.png',
                      width: 28,
                      height: 28,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.savings_rounded,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                          )
                        else
                          Text(
                            hoje,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // 🌞 / 🌜 botão de alternância de tema
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: cs.onSurface,
                ),
                onPressed: () => ThemeController.instance.toggleTheme(),
                tooltip: 'Alternar tema',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
