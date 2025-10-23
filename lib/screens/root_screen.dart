import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _indexAtual = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = const [
    HomeScreen(),
    DashboardScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  final List<String> _titulos = [
    'Início',
    'Dashboard',
    'Perfil',
    'Definições',
  ];

  // 🌈 função que o Drawer usa para navegar entre as páginas
  void _handleNavigation(String destino) {
    Navigator.pop(context); // fecha o Drawer
    switch (destino) {
      case 'home':
        _mudarPagina(0);
        break;
      case 'dashboard':
        _mudarPagina(1);
        break;
      case 'perfil':
        _mudarPagina(2);
        break;
      case 'definicoes':
        _mudarPagina(3);
        break;
    }
  }

  void _mudarPagina(int index) {
    setState(() => _indexAtual = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final hoje = DateFormat('EEE, d MMM yyyy', 'pt_PT').format(DateTime.now());
    final brand = Theme.of(context).extension<BrandStyles>()!;

    return Scaffold(
      key: _scaffoldKey,

      // 🌈 Drawer com dados do utilizador e animações suaves
      drawer: AppDrawer(onNavigate: _handleNavigation),

      // 🌟 Cabeçalho com botão ☰
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
        child: AppHeader(
          title: _titulos[_indexAtual],
          subtitle: hoje,
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),

      // 🧩 Conteúdo principal
      body: Container(
        decoration: BoxDecoration(gradient: brand.surfaceGradient),
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _screens,
        ),
      ),

      // 🔽 Barra de navegação inferior
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexAtual,
        onDestinationSelected: _mudarPagina,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'Definições',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
