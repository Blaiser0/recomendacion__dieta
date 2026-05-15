/// Estadísticas agregadas de [registros_consulta] para el dashboard (tiempo real).
class DashboardStats {
  const DashboardStats({
    required this.totalRegistros,
    required this.consultasUltimos7Dias,
    required this.porNivel,
    required this.dietasDistintas,
  });

  final int totalRegistros;
  final int consultasUltimos7Dias;
  final Map<String, int> porNivel;
  final int dietasDistintas;

  static const ordenNiveles = <String>[
    'Obesidad_Tipo_I',
    'Obesidad_Tipo_II',
    'Obesidad_Tipo_III',
    'Peso_insuficiente',
    'Peso_normal',
    'Sobrepeso_Nivel_I',
    'Sobrepeso_Nivel_II',
  ];
}
