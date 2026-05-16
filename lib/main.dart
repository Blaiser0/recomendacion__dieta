import 'package:flutter/material.dart';

import 'services/firebase_bootstrap.dart';
import 'theme/dietwise_theme.dart';
import 'ui/auth/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseBootstrap.start();
  runApp(const DietWiseApp());
}

class DietWiseApp extends StatelessWidget {
  const DietWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DietWise',
      debugShowCheckedModeBanner: false,
      theme: buildDietWiseTheme(),
      home: const SplashPage(),
    );
  }
}
