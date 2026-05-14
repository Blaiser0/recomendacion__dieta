import 'package:cloud_firestore/cloud_firestore.dart';

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
