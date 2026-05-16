
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

// -----------------------------------------------------------------------------
// PROYECTO FIREBASE DE ESTA APP: proyecto-ia-dieta
// (ver lib/firebase_options.dart)
//
// Si ves "operation-not-allowed" al registrarte:
//   https://console.firebase.google.com/project/proyecto-ia-dieta/authentication/providers
//   → Correo electrónico/Contraseña → Habilitar → Guardar
//
// Si la subida de foto falla con "permission-denied":
//   Firebase Console → Storage → Reglas → publicar storage.rules de la raíz del repo.
// -----------------------------------------------------------------------------

/// Autenticación Firebase + perfil en Firestore `usuarios/{uid}`.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  static const String coleccionUsuarios = 'usuarios';

  /// Debe coincidir con [DefaultFirebaseOptions] / google-services.json.
  static const String firebaseProjectId = 'proyecto-ia-dieta';

  static const String urlConsolaAuthEmail =
      'https://console.firebase.google.com/project/$firebaseProjectId/authentication/providers';

  static const String mensajeErrorGenerico =
      'Ocurrió un error inesperado. Por favor, inténtelo más tarde.';

  User? get usuarioActual => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  static String _codigoAuth(FirebaseAuthException e) {
    final c = e.code.trim();
    if (c.startsWith('auth/')) return c.substring(5);
    return c;
  }

  static String _codigoFirebase(FirebaseException e) {
    final c = e.code.trim();
    if (c.contains('/')) return c.split('/').last;
    return c;
  }

  /// Correo/contraseña no habilitado en la consola (causa habitual del error en inglés).
  bool esEmailPasswordNoHabilitado(FirebaseAuthException e) {
    final code = _codigoAuth(e);
    if (code == 'operation-not-allowed') return true;
    final msg = (e.message ?? '').toLowerCase();
    return msg.contains('operation is not allowed') ||
        msg.contains('sign-in provider is disabled');
  }

  bool esFirestorePermisoDenegado(FirebaseException e) {
    return _codigoFirebase(e) == 'permission-denied';
  }

  bool esStorageSinPermiso(FirebaseException e) {
    final c = _codigoFirebase(e);
    return c == 'unauthorized' ||
        c == 'permission-denied' ||
        c == 'unauthenticated';
  }

  bool esErrorConfiguracionAuth(FirebaseAuthException e) {
    if (esEmailPasswordNoHabilitado(e)) return true;
    switch (_codigoAuth(e)) {
      case 'admin-restricted-operation':
      case 'invalid-api-key':
      case 'app-not-authorized':
        return true;
      default:
        return false;
    }
  }

  Future<UserCredential> iniciarSesion({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> enviarRestablecimientoContrasena(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserCredential> registrar({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'No se pudo crear el usuario.',
      );
    }

    try {
      await user.updateDisplayName(nombre.trim());

      await _db.collection(coleccionUsuarios).doc(user.uid).set({
        'nombre': nombre.trim(),
        'email': email.trim(),
        'creadoEn': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      try {
        await user.delete();
      } catch (_) {}
      rethrow;
    }

    return cred;
  }

  Future<String?> nombreEnFirestore(String uid) async {
    final snap = await _db.collection(coleccionUsuarios).doc(uid).get();
    if (!snap.exists) return null;
    return snap.data()?['nombre'] as String?;
  }

  Future<Map<String, dynamic>?> obtenerPerfilUsuario(String uid) async {
    final snap = await _db.collection(coleccionUsuarios).doc(uid).get();
    if (!snap.exists) return null;
    return snap.data();
  }

  /// Escucha cambios del documento `usuarios/{uid}` (p. ej. [fotoUrl]).
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamPerfilUsuario(
    String uid,
  ) {
    return _db.collection(coleccionUsuarios).doc(uid).snapshots();
  }

  /// Sube la imagen a `perfiles/{uid}.jpg`, obtiene URL y guarda [fotoUrl] en Firestore.
  Future<String> subirFotoPerfilStorage({
    required String uid,
    required Uint8List bytes,
  }) async {
    final ref = _storage.ref().child('perfiles/$uid.jpg');
    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      ),
    );
    final url = await ref.getDownloadURL();
    await _db.collection(coleccionUsuarios).doc(uid).set(
      {
        'fotoUrl': url,
        'actualizadoEn': FieldValue.serverTimestamp(),
        'fotoBase64': FieldValue.delete(),
      },
      SetOptions(merge: true),
    );
    return url;
  }

  Future<void> actualizarPerfilUsuario({
    required String uid,
    required String nombre,
    required String apellido,
    int? edad,
    double? altura,
    double? peso,
    required bool recordatorios,
  }) async {
    final data = <String, Object?>{
      'nombre': nombre.trim(),
      'apellido': apellido.trim(),
      'edad': edad,
      'altura': altura,
      'peso': peso,
      'recordatorios': recordatorios,
      'actualizadoEn': FieldValue.serverTimestamp(),
    };
    await _db.collection(coleccionUsuarios).doc(uid).set(
          data,
          SetOptions(merge: true),
        );
    final display = '${nombre.trim()} ${apellido.trim()}'.trim();
    if (display.isNotEmpty) {
      await _auth.currentUser?.updateDisplayName(display);
    }
  }

  Future<void> cerrarSesion() => _auth.signOut();

  String mensajeEmailPasswordNoHabilitado() =>
      'El registro con correo y contraseña no está activado en Firebase.\n\n'
      'Proyecto: $firebaseProjectId\n\n'
      '1. Abra la consola de Firebase (enlace en la documentación del proyecto).\n'
      '2. Vaya a Authentication → Sign-in method.\n'
      '3. Active «Correo electrónico/Contraseña» (Email/Password) y pulse Guardar.\n'
      '4. Espere un minuto, cierre la app por completo y vuelva a intentar.\n\n'
      'Compruebe que está en el proyecto correcto: $firebaseProjectId '
      '(no otro proyecto de su cuenta Google).';

  String mensajeFirestorePermisoDenegado() =>
      'Su cuenta se creó en Authentication, pero no se pudo guardar el perfil en Firestore.\n\n'
      'Publique reglas que permitan escribir en usuarios/{uid} para el usuario autenticado. '
      'En este repositorio hay un archivo firestore.rules de referencia.\n\n'
      'Consola: Firestore → Reglas → proyecto $firebaseProjectId';

  static const String urlConsolaStorageReglas =
      'https://console.firebase.google.com/project/$firebaseProjectId/storage/rules';

  String mensajeStoragePermisoDenegado() =>
      'No se pudo subir la foto (permiso denegado en Firebase Storage).\n\n'
      '1. En Firebase Console, abra Storage y active el servicio si aún no está creado.\n'
      '2. Publique las reglas del archivo storage.rules de este proyecto (desde la raíz del repo: firebase deploy --only storage).\n'
      '3. Las reglas deben permitir que el usuario autenticado escriba en perfiles/{suUid}.jpg.\n\n'
      'Enlace directo a reglas de Storage:\n$urlConsolaStorageReglas';

  String mensajeErrorStorage(FirebaseException e) {
    if (esStorageSinPermiso(e)) {
      return mensajeStoragePermisoDenegado();
    }
    switch (_codigoFirebase(e)) {
      case 'canceled':
        return 'La subida se canceló.';
      case 'unknown':
      case 'bucket-not-found':
      case 'project-not-found':
        return 'Storage no está disponible o el depósito del proyecto no existe. '
            'Revise que Storage esté activado en la consola de Firebase (proyecto $firebaseProjectId).';
      case 'retry-limit-exceeded':
      case 'network-request-failed':
        return 'Error de red al subir la imagen. Compruebe su conexión e inténtelo de nuevo.';
      case 'quota-exceeded':
        return 'Se superó la cuota de almacenamiento del proyecto.';
      default:
        return 'Error al subir la imagen (${e.code}). Si persiste, revise Storage en la consola.';
    }
  }

  String mensajeErrorConfiguracionAuthGenerico() =>
      'Error de configuración en Firebase (proyecto $firebaseProjectId). '
      'Revise Authentication y que la app use el mismo proyecto que la consola.';

  String mensajeError(FirebaseAuthException e) {
    if (esEmailPasswordNoHabilitado(e)) {
      return mensajeEmailPasswordNoHabilitado();
    }
    if (esErrorConfiguracionAuth(e)) {
      return mensajeErrorConfiguracionAuthGenerico();
    }
    switch (_codigoAuth(e)) {
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'user-not-found':
        return 'No existe una cuenta con ese correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'email-already-in-use':
        return 'Ese correo ya está registrado.';
      case 'weak-password':
        return 'La contraseña es demasiado débil (mínimo 6 caracteres).';
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intente más tarde.';
      case 'network-request-failed':
        return 'Sin conexión. Verifique su red e inténtelo de nuevo.';
      case 'user-null':
        return mensajeErrorGenerico;
      default:
        return mensajeErrorGenerico;
    }
  }

  String mensajeErrorFirestore(FirebaseException e) {
    if (esFirestorePermisoDenegado(e)) {
      return mensajeFirestorePermisoDenegado();
    }
    return 'Error en Firestore (${e.code}). $mensajeErrorGenerico';
  }

  String mensajeParaError(Object error) {
    if (error is FirebaseAuthException) {
      return mensajeError(error);
    }
    if (error is FirebaseException) {
      if (error.plugin == 'firebase_storage') {
        return mensajeErrorStorage(error);
      }
      return mensajeErrorFirestore(error);
    }
    return mensajeErrorGenerico;
  }

  /// Solo en depuración: ayuda a distinguir Auth vs Firestore.
  String? detalleTecnicoDebug(Object error) {
    if (!kDebugMode) return null;
    if (error is FirebaseAuthException) {
      return 'Auth código: ${error.code}';
    }
    if (error is FirebaseException) {
      return 'Firebase código: ${error.code} (${error.plugin})';
    }
    return error.runtimeType.toString();
  }
}
