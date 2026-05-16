import 'package:flutter/material.dart';

import '../../theme/dietwise_theme.dart';
import 'auth_gate.dart';
import 'dietwise_auth_widgets.dart';

/// Splash: logo completo centrado, 1,5 s, fade al acceso.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _duracionVisible = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(_duracionVisible, _irAlAcceso);
  }

  void _irAlAcceso() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthGate(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DietWiseColors.pastelBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: const [
            DietWiseLogoCompleto(),
          ],
        ),
      ),
    );
  }
}
