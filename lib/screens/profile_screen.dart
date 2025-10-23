import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nome: ${user?.displayName ?? '-'}'),
            const SizedBox(height: 8),
            Text('Email: ${user?.email ?? '-'}'),
            const SizedBox(height: 8),
            Text('UID: ${user?.uid ?? '-'}'),
          ],
        ),
      ),
    );
  }
}
