import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../screens/root_screen.dart';
import '../screens/login_screen.dart';

class AuthService {
  // Singleton
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

  /// 🔹 Verifica se existe um utilizador autenticado
  User? get currentUser => _auth.currentUser;

  // =============================
  // LOGIN COM GOOGLE
  // =============================
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      // Inicia o fluxo de autenticação
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login cancelado pelo utilizador')),
        );
        return;
      }

      final googleAuth = await googleUser.authentication;

      // Cria credencial do Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Inicia sessão no Firebase
      await _auth.signInWithCredential(credential);

      if (!context.mounted) return;
      await Future.delayed(Duration.zero); // aguarda 1 frame para estabilidade

      // ✅ Vai para o ecrã principal
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Erro no login Google: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao iniciar sessão com Google')),
      );
    }
  }

  // =============================
  // LOGOUT
  // =============================
  Future<void> signOut(BuildContext context) async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();

      if (!context.mounted) return;
      await Future.delayed(Duration.zero);

      // ✅ Redireciona para o ecrã de login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Erro ao terminar sessão: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao terminar sessão')),
      );
    }
  }
}
