import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/firebase_bootstrap.dart';
import '../../theme/dietwise_theme.dart';
import '../main_shell.dart';
import 'login_page.dart';

/// Tras el splash: espera Firebase si aún no terminó, luego login o shell.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: FirebaseBootstrap.ensureInitialized(),
      builder: (context, initSnap) {
        if (initSnap.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: DietWiseColors.pastelBg,
            body: Center(
              child: CircularProgressIndicator(
                color: DietWiseColors.buttonGray,
              ),
            ),
          );
        }
        if (initSnap.hasError) {
          return Scaffold(
            backgroundColor: DietWiseColors.pastelBg,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudo conectar con Firebase.\n${initSnap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final auth = AuthService();
        return StreamBuilder<User?>(
          stream: auth.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: DietWiseColors.pastelBg,
                body: Center(
                  child: CircularProgressIndicator(
                    color: DietWiseColors.buttonGray,
                  ),
                ),
              );
            }
            if (snapshot.hasData) {
              return const MainShell();
            }
            return const LoginPage();
          },
        );
      },
    );
  }
}
