import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatefulWidget {
  final void Function(String destino) onNavigate;

  const AppDrawer({super.key, required this.onNavigate});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _fadeHeader;
  late final Animation<double> _fadeMain;
  late final Animation<double> _fadeFooter;
  late final Animation<Offset> _slideHeader;
  late final Animation<Offset> _slideMain;
  late final Animation<Offset> _slideFooter;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    // 🎬 Staggered intervals para fluidez
    _fadeHeader = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
    _fadeMain = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    );
    _fadeFooter = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );

    _slideHeader = Tween<Offset>(
      begin: const Offset(-0.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3)),
    );

    _slideMain = Tween<Offset>(
      begin: const Offset(-0.25, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8)),
    );

    _slideFooter = Tween<Offset>(
      begin: const Offset(-0.25, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0)),
    );

    _controller.forward(); // ▶️ anima ao abrir
  }

  Future<void> _closeWithAnimation(BuildContext context) async {
    await _controller.reverse(); // ⏪ anima ao fechar
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final cs = Theme.of(context).colorScheme;
    final brand = Theme.of(context).extension<BrandStyles>()!;

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      backgroundColor: cs.surface,
      child: SafeArea(
        child: Column(
          children: [
            // 🎩 Cabeçalho do utilizador
            FadeTransition(
              opacity: _fadeHeader,
              child: SlideTransition(
                position: _slideHeader,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: brand.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : const AssetImage('assets/icon.png')
                                as ImageProvider,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Utilizador convidado',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              user?.email ?? 'Sem sessão iniciada',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 📱 Itens principais
            Expanded(
              child: FadeTransition(
                opacity: _fadeMain,
                child: SlideTransition(
                  position: _slideMain,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _DrawerItem(
                        icon: Icons.home_rounded,
                        label: 'Início',
                        onTap: () {
                          _closeWithAnimation(context);
                          widget.onNavigate('home');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.bar_chart_rounded,
                        label: 'Dashboard',
                        onTap: () {
                          _closeWithAnimation(context);
                          widget.onNavigate('dashboard');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.person_rounded,
                        label: 'Perfil',
                        onTap: () {
                          _closeWithAnimation(context);
                          widget.onNavigate('perfil');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.settings_rounded,
                        label: 'Definições',
                        onTap: () {
                          _closeWithAnimation(context);
                          widget.onNavigate('definicoes');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 🎸 Rodapé: divisor + sobre + sair
            FadeTransition(
              opacity: _fadeFooter,
              child: SlideTransition(
                position: _slideFooter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Divider(
                      color: cs.outlineVariant.withValues(alpha: .3),
                      thickness: 1,
                      height: 16,
                    ),
                    _DrawerItem(
                      icon: Icons.info_outline_rounded,
                      label: 'Sobre',
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Poupe Hoje',
                          applicationVersion: '1.0.0',
                          children: const [
                            Text('App de gestão de finanças pessoais.'),
                          ],
                        );
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.logout_rounded,
                      label: 'Terminar sessão',
                      color: cs.error,
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Terminar sessão?'),
                            content: const Text(
                                'Tem a certeza que deseja sair da sua conta Google?'),
                            actions: [
                              TextButton(
                                child: const Text('Cancelar'),
                                onPressed: () => Navigator.pop(ctx, false),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: cs.error),
                                child: const Text('Sair'),
                                onPressed: () => Navigator.pop(ctx, true),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await _closeWithAnimation(context);
                          await AuthService.instance.signOut(context);
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 6),
                      child: Text(
                        'Poupe Hoje © ${DateTime.now().year}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: .6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colorFinal = color ?? cs.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: colorFinal),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: colorFinal,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
