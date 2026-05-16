import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

/// Inicializa Firebase en segundo plano para no bloquear el splash.
abstract final class FirebaseBootstrap {
  static Future<void>? _init;

  static Future<void> ensureInitialized() {
    return _init ??= Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static void start() {
    ensureInitialized();
  }
}
