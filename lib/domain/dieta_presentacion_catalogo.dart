/// Datos de interfaz para cada salida del modelo. La clave [nivelModelo] no debe
/// mostrarse al usuario; solo sirve para enlazar con la IA / Firestore.
class MacroSlicePresentacion {
  const MacroSlicePresentacion(this.etiqueta, this.porcentaje);

  /// Etiqueta legible del segmento del gráfico (sin jerga de modelo).
  final String etiqueta;
  final double porcentaje;
}

class DietaPresentacion {
  const DietaPresentacion({
    required this.nivelModelo,
    required this.titulo,
    required this.objetivo,
    required this.macros,
    required this.alimentos,
    required this.habitos,
  });

  /// Clave técnica del dataset; **no** usar en textos de UI.
  final String nivelModelo;
  final String titulo;
  final String objetivo;
  final List<MacroSlicePresentacion> macros;
  final List<String> alimentos;
  final List<String> habitos;
}

/// Orden pedagógico de las tarjetas (de menor a mayor intervención metabólica).
const ordenNivelesDietasUi = <String>[
  'Peso_insuficiente',
  'Peso_normal',
  'Sobrepeso_Nivel_I',
  'Sobrepeso_Nivel_II',
  'Obesidad_Tipo_I',
  'Obesidad_Tipo_II',
  'Obesidad_Tipo_III',
];

/// Catálogo fijo: categorías IA → contenido amigable (textos según especificación).
abstract final class DietaPresentacionCatalogo {
  static final Map<String, DietaPresentacion> _porNivel = {
    'Peso_insuficiente': DietaPresentacion(
      nivelModelo: 'Peso_insuficiente',
      titulo: 'Dieta Hipercalórica',
      objetivo:
          'Aumenta tu masa muscular y ganar peso de forma saludable. No se trata de comer chatarra, sino de consumir alimentos densos en nutrientes y energía.',
      macros: const [
        MacroSlicePresentacion('Carbohidratos complejos', 50),
        MacroSlicePresentacion('Proteínas', 25),
        MacroSlicePresentacion('Grasas saludables', 25),
      ],
      alimentos: const [
        'Castaña (energía)',
        'Maca y Kiwicha (músculo)',
        'Aguaje (vitaminas)',
      ],
      habitos: const [
        'Hidratación (batidos maca)',
        'Movimiento (fuerza)',
        'Rutina (5 comidas)',
      ],
    ),
    'Peso_normal': DietaPresentacion(
      nivelModelo: 'Peso_normal',
      titulo: 'Dieta Equilibrada',
      objetivo:
          'Mantener tu excelente estado de salud actual. No necesitas restringir nada, solo mantener el equilibrio perfecto que tu cuerpo ya tiene.',
      macros: const [
        MacroSlicePresentacion('Verduras y frutas', 50),
        MacroSlicePresentacion('Proteínas magras', 25),
        MacroSlicePresentacion('Carbohidratos', 25),
      ],
      alimentos: const [
        'Quinua (proteína)',
        'Camu Camu (vitamina C)',
        'Paiche (magro)',
      ],
      habitos: const [
        'Hidratación (2 L agua)',
        'Movimiento (30 min actividad)',
        'Cocción (poco aceite)',
      ],
    ),
    'Sobrepeso_Nivel_I': DietaPresentacion(
      nivelModelo: 'Sobrepeso_Nivel_I',
      titulo: 'Dieta Hipocalórica leve',
      objetivo:
          'Un control de peso preventivo. Cortar las grasas saturadas es la forma más fácil y rápida de reducir calorías sin porciones pequeñas.',
      macros: const [
        MacroSlicePresentacion('Vegetales y fibra', 50),
        MacroSlicePresentacion('Proteínas', 30),
        MacroSlicePresentacion('Grasas saludables', 20),
      ],
      alimentos: const [
        'Palmito (saciante)',
        'Doncella / Gamitana (pescado ligero)',
        'Cañihua (energía limpia)',
      ],
      habitos: const [
        'Hidratación (Mate Muña)',
        'Cocción (plancha / vapor)',
        'Movimiento (caminatas)',
      ],
    ),
    'Sobrepeso_Nivel_II': DietaPresentacion(
      nivelModelo: 'Sobrepeso_Nivel_II',
      titulo: 'Dieta de Bajo Índice Glucémico',
      objetivo:
          'Controla la ansiedad por comer y estabilizar tu glucosa en la sangre para evitar llegar a la obesidad.',
      macros: const [
        MacroSlicePresentacion('Vegetales y fibra', 50),
        MacroSlicePresentacion('Proteínas', 30),
        MacroSlicePresentacion('Carbohidratos de absorción lenta', 20),
      ],
      alimentos: const [
        'Yacón (endulzante natural)',
        'Tarwi (poca carga glucémica)',
        'Pitahaya (digestión)',
      ],
      habitos: const [
        'Hidratación (infusiones)',
        'Movimiento (15 min post-comida)',
        'Rutina (cenar temprano)',
      ],
    ),
    'Obesidad_Tipo_I': DietaPresentacion(
      nivelModelo: 'Obesidad_Tipo_I',
      titulo: 'Dieta Hipocalórica estricta (baja en carbohidratos)',
      objetivo:
          'Intervención metabólica. Al reducir drásticamente los carbohidratos, obligamos al cuerpo a usar grasa como combustible.',
      macros: const [
        MacroSlicePresentacion('Verduras verdes', 50),
        MacroSlicePresentacion('Proteínas', 30),
        MacroSlicePresentacion('Grasas saludables', 20),
      ],
      alimentos: const [
        'Aceite Sacha Inchi (energía)',
        'Cacao puro (ansiedad)',
        'Chonta (sustituto pasta)',
      ],
      habitos: const [
        'Hidratación (2,5 L agua / limón)',
        'Movimiento (bajo impacto)',
        'Rutina (ayuno 12 h)',
      ],
    ),
    'Obesidad_Tipo_II': DietaPresentacion(
      nivelModelo: 'Obesidad_Tipo_II',
      titulo: 'Dieta Alta en Proteínas y Baja en Carbohidratos',
      objetivo:
          'Generar máxima saciedad para que bajes de peso sin pasar hambre, protegiendo tu masa muscular.',
      macros: const [
        MacroSlicePresentacion('Proteínas', 40),
        MacroSlicePresentacion('Vegetales y fibra', 30),
        MacroSlicePresentacion('Grasas saludables', 30),
      ],
      alimentos: const [
        'Tarwi (proteína vegetal)',
        'Sacha Inchi (omega 3)',
        'Cecina magra (sin freír)',
      ],
      habitos: const [
        'Hidratación (Mate Guayusa)',
        'Movimiento (calistenia / pesas)',
        'Rutina (no picar)',
      ],
    ),
    'Obesidad_Tipo_III': DietaPresentacion(
      nivelModelo: 'Obesidad_Tipo_III',
      titulo: 'Dieta Muy baja en calorías',
      objetivo:
          'Intervención intensiva para reducir peso drásticamente, protegiendo salud cardiovascular y quemando grasa.',
      macros: const [
        MacroSlicePresentacion('Grasas saludables', 60),
        MacroSlicePresentacion('Proteínas magras', 30),
        MacroSlicePresentacion('Fibra verde', 10),
      ],
      alimentos: const [
        'Castaña / Ungurahui (grasas buenas)',
        'Paiche (músculo)',
        'Hojas verdes locales (digestión)',
      ],
      habitos: const [
        'Hidratación (Uña de Gato)',
        'Cocción (Patarashca)',
        'Movimiento (supervisado)',
      ],
    ),
  };

  static DietaPresentacion? paraNivel(String nivelModelo) =>
      _porNivel[nivelModelo];

  static Iterable<DietaPresentacion> todasEnOrdenUi() sync* {
    for (final k in ordenNivelesDietasUi) {
      final d = _porNivel[k];
      if (d != null) yield d;
    }
  }
}
