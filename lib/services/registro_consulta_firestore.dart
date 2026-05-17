import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/dieta_presentacion_catalogo.dart';
import '../models/dashboard_stats.dart';

/// Persistencia en Firestore de cada consulta (predicción + dieta asociada).
class RegistroConsultaFirestore {
  RegistroConsultaFirestore({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const String coleccion = 'registros_consulta';

  String? get _uid => _auth.currentUser?.uid;

  Future<void> guardar({
    required String nivelObesidad,
    required String dietaRecomendada,
    double? confianzaPrediccion,
    Map<String, Object?>? datosEntrada,
  }) {
    final uid = _uid;
    if (uid == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Debe iniciar sesión para guardar una consulta.',
      );
    }

    final doc = <String, Object?>{
      'userId': uid,
      'creadoEn': FieldValue.serverTimestamp(),
      'nivelObesidad': nivelObesidad,
      'dietaRecomendada': dietaRecomendada,
    };
    if (confianzaPrediccion != null) {
      doc['confianzaPrediccion'] = confianzaPrediccion;
    }
    if (datosEntrada != null) {
      doc['datosEntrada'] = datosEntrada;
    }
    return _db.collection(coleccion).add(doc);
  }

  DashboardStats _statsDesdeSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final now = DateTime.now();
    final inicioSemana = now.subtract(const Duration(days: 7));
    var consultasUltimos7Dias = 0;
    final porNivel = {for (final k in ordenNivelesDietasUi) k: 0};
    var total = 0;

    for (final doc in snap.docs) {
      final data = doc.data();
      total++;

      final nivel = data['nivelObesidad'] as String?;
      if (DietaPresentacionCatalogo.esNivelCatalogo(nivel)) {
        porNivel[nivel!] = porNivel[nivel]! + 1;
      }
      final creado = data['creadoEn'];
      if (creado is Timestamp && creado.toDate().isAfter(inicioSemana)) {
        consultasUltimos7Dias++;
      }
    }

    return DashboardStats(
      totalRegistros: total,
      consultasUltimos7Dias: consultasUltimos7Dias,
      porNivel: porNivel,
      totalDietasCatalogo: DietaPresentacionCatalogo.cantidadDietas,
    );
  }

  DistribucionGlobalGrafico _distribucionGlobalDesdeSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final porNivel = {for (final k in ordenNivelesDietasUi) k: 0};
    for (final doc in snap.docs) {
      final nivel = doc.data()['nivelObesidad'] as String?;
      if (DietaPresentacionCatalogo.esNivelCatalogo(nivel)) {
        porNivel[nivel!] = porNivel[nivel]! + 1;
      }
    }
    return DistribucionGlobalGrafico(porNivel: porNivel);
  }

  /// Gráfico de dona: todos los `registros_consulta` (sin filtro por usuario).
  Stream<DistribucionGlobalGrafico> watchDistribucionGlobalGrafico() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(DistribucionGlobalGrafico.vacio());
      }
      return _db
          .collection(coleccion)
          .snapshots()
          .map(_distribucionGlobalDesdeSnapshot);
    });
  }

  /// Tarjetas del inicio: solo consultas del usuario autenticado.
  Stream<DashboardStats> watchDashboardStats() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(DashboardStats.vacio());
      }
      final uid = user.uid;
      return _db
          .collection(coleccion)
          .where('userId', isEqualTo: uid)
          .snapshots()
          .map(_statsDesdeSnapshot);
    });
  }

  Future<int> contarConsultasUsuario(String uid) async {
    final snap =
        await _db.collection(coleccion).where('userId', isEqualTo: uid).get();
    return snap.docs.length;
  }

  /// Conteo en tiempo real de `registros_consulta` del usuario autenticado.
  Stream<int> watchConteoConsultasUsuario() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(0);
      }
      final uid = user.uid;
      return _db
          .collection(coleccion)
          .where('userId', isEqualTo: uid)
          .snapshots()
          .map((snap) => snap.docs.length);
    });
  }

  /// Última consulta del usuario (sin índice compuesto; orden en cliente).
  Future<Map<String, Object?>?> ultimaConsultaParaUsuario(String uid) async {
    final snap =
        await _db.collection(coleccion).where('userId', isEqualTo: uid).get();
    if (snap.docs.isEmpty) return null;
    QueryDocumentSnapshot<Map<String, dynamic>>? best;
    Timestamp? bestTs;
    for (final d in snap.docs) {
      final raw = d.data()['creadoEn'];
      if (raw is Timestamp) {
        if (bestTs == null || raw.compareTo(bestTs) > 0) {
          bestTs = raw;
          best = d;
        }
      } else {
        best ??= d;
      }
    }
    best ??= snap.docs.first;
    final m = Map<String, Object?>.from(best.data());
    m['id'] = best.id;
    return m;
  }

  Stream<List<Map<String, Object?>>> historial({int limite = 100}) {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(const []);
      }
      final uid = user.uid;
      return _db
          .collection(coleccion)
          .where('userId', isEqualTo: uid)
          .snapshots()
          .map((snap) {
        final docs = snap.docs.toList()
          ..sort((a, b) {
            final ta = a.data()['creadoEn'];
            final tb = b.data()['creadoEn'];
            if (ta is Timestamp && tb is Timestamp) {
              return tb.compareTo(ta);
            }
            return 0;
          });
        return docs.take(limite).map((d) {
          final m = Map<String, Object?>.from(d.data());
          final creado = m['creadoEn'];
          if (creado is Timestamp) {
            m['creadoEn'] = creado.toDate().toIso8601String();
          }
          return {'id': d.id, ...m};
        }).toList();
      });
    });
  }
}
