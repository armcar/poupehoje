import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthService {
  // Singleton
  AuthService._();
  static final instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 Login com email e password
  Future<void> signInWithEmail(
      String email, String password, BuildContext context) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // 🔸 Cria/atualiza o perfil no Firestore
      final user = _auth.currentUser;
      if (user != null) {
        await _createOrUpdateUserProfile(user);
      }
    } on FirebaseAuthException catch (e) {
      _showError(context, _translateError(e));
    } catch (e) {
      _showError(context, 'Erro inesperado ao autenticar.');
    }
  }

  /// 🔹 Criação de conta com email e password (agora com nome opcional)
  Future<void> signUpWithEmail(
    String email,
    String password,
    BuildContext context, {
    String? name, // 👈 novo parâmetro
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = _auth.currentUser;

      if (user != null) {
        // 👇 Atualiza o nome no perfil do FirebaseAuth
        if (name != null && name.isNotEmpty) {
          await user.updateDisplayName(name);
        }

        // 👇 Cria o perfil completo no Firestore
        await _createOrUpdateUserProfile(user, isNew: true, name: name);
      }
    } on FirebaseAuthException catch (e) {
      _showError(context, _translateError(e));
    } catch (e) {
      _showError(context, 'Erro inesperado ao criar conta.');
    }
  }

  /// 🔹 Login com Google
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // utilizador cancelou

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      final user = _auth.currentUser;
      if (user != null) {
        await _createOrUpdateUserProfile(user);
      }
    } on FirebaseAuthException catch (e) {
      _showError(context, _translateError(e));
    } catch (e) {
      _showError(context, 'Erro inesperado ao autenticar com o Google.');
    }
  }

  /// 🔹 Logout
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  /// 🔹 Utilizador atual
  User? get currentUser => _auth.currentUser;

  /// 🔹 Stream de autenticação (para redirecionar dinamicamente)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==========================================================================
  // 🔹 PERFIL DO UTILIZADOR NO FIRESTORE
  // ==========================================================================

  Future<void> _createOrUpdateUserProfile(
    User user, {
    bool isNew = false,
    String? name, // 👈 novo parâmetro
  }) async {
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    final displayName = name ?? user.displayName ?? '';

    if (!snapshot.exists) {
      // 🔸 Novo utilizador → cria documento inicial
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'photoURL': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'locale': 'pt_PT',
        'theme': 'system',
        'stats': {
          'logins': 1,
          'transactions': 0,
          'saldo': 0.0,
        },
      });
    } else {
      // 🔸 Utilizador existente → apenas atualiza info básica
      await userDoc.update({
        'updatedAt': FieldValue.serverTimestamp(),
        'displayName': displayName.isNotEmpty
            ? displayName
            : snapshot.data()?['displayName'] ?? '',
        'photoURL': user.photoURL ?? snapshot.data()?['photoURL'] ?? '',
        'stats.logins': FieldValue.increment(1),
      });
    }
  }

  // ==========================================================================
  // 🔹 GESTÃO DE ERROS
  // ==========================================================================

  String _translateError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este email já está registado.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'weak-password':
        return 'A password é demasiado fraca.';
      case 'user-not-found':
        return 'Utilizador não encontrado.';
      case 'wrong-password':
        return 'Password incorreta.';
      case 'network-request-failed':
        return 'Erro de rede. Verifique a sua ligação à internet.';
      case 'too-many-requests':
        return 'Demasiadas tentativas. Tente novamente mais tarde.';
      default:
        return e.message ?? 'Ocorreu um erro inesperado.';
    }
  }

  // ==========================================================================
  // 🔹 ALERTAS E FEEDBACK
  // ==========================================================================

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade400,
      ),
    );
  }
}
