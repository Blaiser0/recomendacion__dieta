import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dashboard_stats.dart';

/// Persistencia en Firestore de cada consulta (predicción + dieta asociada).
class RegistroConsultaFirestore {
  RegistroConsultaFirestore({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String coleccion = 'registros_consulta';

  Future<void> guardar({
    required String nivelObesidad,
    required String dietaRecomendada,
    double? confianzaPrediccion,
    Map<String, Object?>? datosEntrada,
  }) {
    final doc = <String, Object?>{
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

  /// Agregados en tiempo real (misma colección que [historial]); al guardar una
  /// consulta el stream emite y el dashboard / gráfico se actualizan.
  Stream<DashboardStats> watchDashboardStats() {
    return _db.collection(coleccion).snapshots().map((snap) {
      final now = DateTime.now();
      final inicioSemana = now.subtract(const Duration(days: 7));
      var consultasUltimos7Dias = 0;
      final porNivel = {for (final k in DashboardStats.ordenNiveles) k: 0};
      final dietas = <String>{};

      for (final doc in snap.docs) {
        final data = doc.data();
        final nivel = data['nivelObesidad'] as String?;
        if (nivel != null && porNivel.containsKey(nivel)) {
          porNivel[nivel] = porNivel[nivel]! + 1;
        }
        final dieta = data['dietaRecomendada'] as String?;
        if (dieta != null && dieta.isNotEmpty) {
          dietas.add(dieta);
        }
        final creado = data['creadoEn'];
        if (creado is Timestamp && creado.toDate().isAfter(inicioSemana)) {
          consultasUltimos7Dias++;
        }
      }

      return DashboardStats(
        totalRegistros: snap.docs.length,
        consultasUltimos7Dias: consultasUltimos7Dias,
        porNivel: porNivel,
        dietasDistintas: dietas.length,
      );
    });
  }

  Stream<List<Map<String, Object?>>> historial({int limite = 100}) {
    return _db
        .collection(coleccion)
        .orderBy('creadoEn', descending: true)
        .limit(limite)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final m = Map<String, Object?>.from(d.data());
            final creado = m['creadoEn'];
            if (creado is Timestamp) {
              m['creadoEn'] = creado.toDate().toIso8601String();
            }
            return {'id': d.id, ...m};
          }).toList(),
        );
  }
}
