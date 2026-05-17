import '../domain/dieta_presentacion_catalogo.dart';

/// Estadísticas agregadas de [registros_consulta] para el dashboard (tiempo real).
class DashboardStats {
  const DashboardStats({
    required this.totalRegistros,
    required this.consultasUltimos7Dias,
    required this.porNivel,
    required this.totalDietasCatalogo,
  });

  final int totalRegistros;
  final int consultasUltimos7Dias;
  final Map<String, int> porNivel;

  /// Planes dietéticos del catálogo (7), no dietas distintas en historial.
  final int totalDietasCatalogo;

  factory DashboardStats.vacio() {
    return DashboardStats(
      totalRegistros: 0,
      consultasUltimos7Dias: 0,
      porNivel: {for (final k in ordenNiveles) k: 0},
      totalDietasCatalogo: DietaPresentacionCatalogo.cantidadDietas,
    );
  }

  /// Misma lista que [DietaPresentacionCatalogo.ordenNivelesDietasUi] (7 niveles/planes).
  static const ordenNiveles = ordenNivelesDietasUi;

  /// Suma de consultas asignadas a los 7 niveles del catálogo (denominador del gráfico).
  int get totalConsultasEnCatalogo {
    var n = 0;
    for (final k in ordenNiveles) {
      n += porNivel[k] ?? 0;
    }
    return n;
  }
}

/// Distribución por nivel de obesidad de **toda** la colección (gráfico global).
class DistribucionGlobalGrafico {
  const DistribucionGlobalGrafico({required this.porNivel});

  final Map<String, int> porNivel;

  factory DistribucionGlobalGrafico.vacio() {
    return DistribucionGlobalGrafico(
      porNivel: {for (final k in ordenNivelesDietasUi) k: 0},
    );
  }

  int get totalConsultasEnCatalogo {
    var n = 0;
    for (final k in ordenNivelesDietasUi) {
      n += porNivel[k] ?? 0;
    }
    return n;
  }
}
