/// Resultado de la clasificación multiclase (softmax en la última capa).
class PrediccionMetabolica {
  const PrediccionMetabolica({
    required this.nivelObesidad,
    required this.confianza,
  });

  /// Etiqueta predicha (misma convención que el dataset / LabelEncoder).
  final String nivelObesidad;

  /// Probabilidad asignada por el modelo a la clase predicha (softmax), en \[0, 1\].
  final double confianza;

  String get confianzaPorcentaje =>
      '${(confianza * 100).clamp(0, 100).toStringAsFixed(1)} %';
}
