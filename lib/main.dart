import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/root_screen.dart';
import 'firebase_options.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_PT', null); // 👈 inicializa locale
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const PoupeHojeApp());
}

class PoupeHojeApp extends StatelessWidget {
  const PoupeHojeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 👇 Escuta o ThemeController
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Poupe Hoje',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode, // 👈 muda o tema dinamicamente
          home: const _AuthWrapper(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('pt', 'PT'),
            Locale('en', 'US'),
          ],
          locale: const Locale('pt', 'PT'),
        );
      },
    );
  }
}

class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 🕐 A inicializar ou a carregar o estado do utilizador
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ Utilizador autenticado → vai para RootScreen
        if (snapshot.hasData) {
          return const RootScreen();
        }

        // ❌ Não autenticado → vai para LoginScreen
        return const LoginScreen().animate().fade(duration: 300.ms);
      },
    );
  }
}
