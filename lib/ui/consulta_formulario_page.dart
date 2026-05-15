import 'package:flutter/material.dart';

import '../domain/dieta_por_nivel.dart';
import '../ml/metabolic_predictor.dart';
import '../services/registro_consulta_firestore.dart';

// Misma línea cromática que la tarjeta "Consulta" del dashboard.
const _kPastelGreenBg = Color(0xFFE8F5E9);
const _kPastelGreen = Color(0xFFA5D6A7);
const _kPastelGreenMid = Color(0xFF81C784);
const _kAccentGreen = Color(0xFF66BB6A);
const _kAccentGreenDark = Color(0xFF43A047);
const _kInputRadius = 15.0;

/// Variables de entrada alineadas con `Dataset_Obesidad_Espanol.csv`.
class _Campo {
  const _Campo({
    required this.columna,
    required this.etiqueta,
    required this.esNumerica,
  });

  final String columna;
  final String etiqueta;
  final bool esNumerica;
}

const _camposOrdenDataset = <_Campo>[
  _Campo(columna: 'Genero', etiqueta: 'Género', esNumerica: false),
  _Campo(columna: 'Edad', etiqueta: 'Edad (años)', esNumerica: true),
  _Campo(columna: 'Altura', etiqueta: 'Altura (m)', esNumerica: true),
  _Campo(columna: 'Peso', etiqueta: 'Peso (kg)', esNumerica: true),
  _Campo(
    columna: 'Antecedentes_Familiares',
    etiqueta: 'Antecedentes familiares de sobrepeso',
    esNumerica: false,
  ),
  _Campo(
    columna: 'Consumo_Hipercalorico',
    etiqueta: 'Consumo de alimentos hipercalóricos',
    esNumerica: false,
  ),
  _Campo(
    columna: 'Consumo_Verduras',
    etiqueta: 'Consumo de verduras (porciones/día)',
    esNumerica: true,
  ),
  _Campo(
    columna: 'Comidas_Diarias',
    etiqueta: 'Comidas principales al día',
    esNumerica: true,
  ),
  _Campo(
    columna: 'Picoteo_Entre_Comidas',
    etiqueta: 'Picoteo entre comidas',
    esNumerica: false,
  ),
  _Campo(columna: 'Fumador', etiqueta: 'Fumador', esNumerica: false),
  _Campo(
    columna: 'Consumo_Agua',
    etiqueta: 'Consumo de agua (litros/día)',
    esNumerica: true,
  ),
  _Campo(
    columna: 'Control_Calórico',
    etiqueta: '¿Hace control de calorías?',
    esNumerica: false,
  ),
  _Campo(
    columna: 'Actividad_Física',
    etiqueta: 'Actividad física (días/semana)',
    esNumerica: true,
  ),
  _Campo(
    columna: 'Sedentarismo_Digital',
    etiqueta: 'Horas frente a pantallas (por día)',
    esNumerica: true,
  ),
  _Campo(
    columna: 'Consumo_Alcohol',
    etiqueta: 'Consumo de alcohol',
    esNumerica: false,
  ),
  _Campo(
    columna: 'Medio_Transporte',
    etiqueta: 'Medio de transporte principal',
    esNumerica: false,
  ),
];

const _pasoPerfil = ['Genero', 'Edad', 'Altura', 'Peso'];
const _pasoAlimentacion = [
  'Antecedentes_Familiares',
  'Consumo_Hipercalorico',
  'Consumo_Verduras',
  'Comidas_Diarias',
  'Picoteo_Entre_Comidas',
];
const _pasoEstilo = [
  'Fumador',
  'Consumo_Agua',
  'Control_Calórico',
  'Consumo_Alcohol',
];
const _pasoActividad = [
  'Actividad_Física',
  'Sedentarismo_Digital',
  'Medio_Transporte',
];

const _titulosPasos = [
  'Perfil',
  'Alimentación',
  'Estilo de vida',
  'Actividad',
];

_Campo? _campoPorColumna(String col) {
  for (final c in _camposOrdenDataset) {
    if (c.columna == col) return c;
  }
  return null;
}

IconData? _iconoNumerico(String col) {
  switch (col) {
    case 'Edad':
      return Icons.cake_outlined;
    case 'Altura':
      return Icons.straighten;
    case 'Peso':
      return Icons.monitor_weight_outlined;
    case 'Consumo_Verduras':
      return Icons.eco_outlined;
    case 'Comidas_Diarias':
      return Icons.restaurant_menu_outlined;
    case 'Consumo_Agua':
      return Icons.water_drop_outlined;
    case 'Actividad_Física':
      return Icons.directions_run;
    case 'Sedentarismo_Digital':
      return Icons.devices_outlined;
    default:
      return Icons.numbers;
  }
}

IconData _iconoTransporte(String valor) {
  switch (valor) {
    case 'Bicicleta':
      return Icons.directions_bike;
    case 'Caminando':
      return Icons.directions_walk;
    case 'Carro':
      return Icons.directions_car;
    case 'Moto':
      return Icons.two_wheeler;
    case 'Transporte_publico':
      return Icons.train_outlined;
    default:
      return Icons.commute;
  }
}

bool _esSiNo(List<String> opciones) =>
    opciones.length == 2 &&
    opciones.contains('si') &&
    opciones.contains('no');

class ConsultaFormularioPage extends StatefulWidget {
  const ConsultaFormularioPage({super.key});

  @override
  State<ConsultaFormularioPage> createState() => _ConsultaFormularioPageState();
}

class _ConsultaFormularioPageState extends State<ConsultaFormularioPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollConsulta = ScrollController();
  final _predictor = MetabolicPredictor.instance;
  final _repo = RegistroConsultaFirestore();

  final _numericos = <String, TextEditingController>{};
  final _focusNumericos = <String, FocusNode>{};
  final _categoricos = <String, String?>{};

  var _cargandoModelo = true;
  var _errorModelo = '';
  var _procesando = false;
  /// Índice del stepper de consulta (0 = primer paso).
  var _currentStep = 0;
  /// Incrementa al reiniciar el formulario para forzar transición del [AnimatedSwitcher].
  var _nonceContenidoPaso = 0;

  static const _totalPasos = 4;

  List<String> _columnasPaso(int p) {
    switch (p) {
      case 0:
        return _pasoPerfil;
      case 1:
        return _pasoAlimentacion;
      case 2:
        return _pasoEstilo;
      case 3:
        return _pasoActividad;
      default:
        return const [];
    }
  }

  @override
  void initState() {
    super.initState();
    for (final c in _camposOrdenDataset) {
      if (c.esNumerica) {
        final ctrl = TextEditingController();
        ctrl.addListener(() => setState(() {}));
        _numericos[c.columna] = ctrl;
        _focusNumericos[c.columna] = FocusNode();
      }
    }
    _inicializarModelo();
  }

  Future<void> _inicializarModelo() async {
    try {
      await _predictor.initialize();
      if (mounted) {
        setState(() {
          _aplicarCategoricosPorDefecto();
          _cargandoModelo = false;
          _errorModelo = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoModelo = false;
          _errorModelo = '$e';
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollConsulta.dispose();
    for (final t in _numericos.values) {
      t.dispose();
    }
    for (final f in _focusNumericos.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _aplicarCategoricosPorDefecto() {
    if (!_predictor.isReady) return;
    final opts = _predictor.categoricalOptions();
    for (final c in _camposOrdenDataset) {
      if (!c.esNumerica) {
        final lista = opts[c.columna];
        _categoricos[c.columna] =
            (lista != null && lista.isNotEmpty) ? lista.first : null;
      }
    }
  }

  /// Limpia controladores, reinicia categóricas, [_currentStep] a 0 y anima el scroll del formulario.
  void _resetForm() {
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    for (final c in _camposOrdenDataset) {
      if (c.esNumerica) {
        _numericos[c.columna]?.clear();
      }
    }
    _aplicarCategoricosPorDefecto();
    _formKey.currentState?.reset();
    setState(() {
      _currentStep = 0;
      _nonceContenidoPaso++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollConsulta.hasClients) {
        _scrollConsulta.animateTo(
          0,
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Map<String, double> _leerNumericos() {
    final m = <String, double>{};
    for (final c in _camposOrdenDataset) {
      if (!c.esNumerica) continue;
      final raw = _numericos[c.columna]!.text.trim().replaceAll(',', '.');
      m[c.columna] = double.parse(raw);
    }
    return m;
  }

  Map<String, String> _leerCategoricos() {
    final m = <String, String>{};
    for (final c in _camposOrdenDataset) {
      if (c.esNumerica) continue;
      final v = _categoricos[c.columna];
      if (v == null || v.isEmpty) {
        throw StateError('Seleccione: ${c.etiqueta}');
      }
      m[c.columna] = v;
    }
    return m;
  }

  Map<String, Object?> _datosParaFirestore() {
    final out = <String, Object?>{};
    for (final c in _camposOrdenDataset) {
      if (c.esNumerica) {
        out[c.columna] = _numericos[c.columna]!.text.trim();
      } else {
        out[c.columna] = _categoricos[c.columna];
      }
    }
    return out;
  }

  bool _numeroValido(String col) {
    final t = _numericos[col]?.text.trim().replaceAll(',', '.') ?? '';
    if (t.isEmpty) return false;
    return double.tryParse(t) != null;
  }

  bool _categoriaValida(String col) {
    final v = _categoricos[col];
    return v != null && v.isNotEmpty;
  }

  bool _validarPaso(int p) {
    for (final col in _columnasPaso(p)) {
      final meta = _campoPorColumna(col);
      if (meta == null) continue;
      if (meta.esNumerica) {
        if (!_numeroValido(col)) return false;
      } else {
        if (!_categoriaValida(col)) return false;
      }
    }
    return true;
  }

  /// Orden de campos numéricos dentro del paso [p] (según el stepper).
  List<String> _columnasNumericasDelPaso(int p) {
    return _columnasPaso(p)
        .where((col) => _campoPorColumna(col)?.esNumerica == true)
        .toList();
  }

  void _enfocarYRevelar(FocusNode node) {
    node.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = node.context;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.28,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  /// Acción del teclado (Siguiente / Listo) en un campo numérico.
  void _onNumericoAccionTeclado(String columna) {
    final orden = _columnasNumericasDelPaso(_currentStep);
    final i = orden.indexOf(columna);
    if (i < 0) return;

    if (i < orden.length - 1) {
      final next = _focusNumericos[orden[i + 1]];
      if (next != null) _enfocarYRevelar(next);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    if (_currentStep >= _totalPasos - 1) {
      return;
    }

    if (!_validarPaso(_currentStep)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete los campos de este paso antes de continuar.'),
        ),
      );
      return;
    }

    _siguiente();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final siguientes = _columnasNumericasDelPaso(_currentStep);
      if (siguientes.isNotEmpty) {
        final first = _focusNumericos[siguientes.first];
        if (first != null) _enfocarYRevelar(first);
      }
    });
  }

  void _siguiente() {
    if (!_validarPaso(_currentStep)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete los campos de este paso antes de continuar.'),
        ),
      );
      return;
    }
    setState(() => _currentStep++);
  }

  void _atras() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _recomendar() async {
    if (_cargandoModelo || !_predictor.isReady) return;
    if (!_validarPaso(_currentStep)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revise los campos de este paso.')),
      );
      return;
    }
    for (var p = 0; p < _totalPasos; p++) {
      if (!_validarPaso(p)) {
        setState(() => _currentStep = p);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Faltan datos en el paso ${_titulosPasos[p]}.')),
        );
        return;
      }
    }

    setState(() => _procesando = true);
    try {
      final nums = _leerNumericos();
      final cats = _leerCategoricos();
      final pred = _predictor.clasificar(
        numericByName: nums,
        categoricalByName: cats,
      );
      final nivel = pred.nivelObesidad;
      final dieta = dietaRecomendadaPara(nivel);

      await _repo.guardar(
        nivelObesidad: nivel,
        dietaRecomendada: dieta,
        confianzaPrediccion: pred.confianza,
        datosEntrada: _datosParaFirestore(),
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          final maxH = MediaQuery.sizeOf(ctx).height * 0.72;
          return AlertDialog(
            title: const Text('Resultado'),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: double.maxFinite,
                maxHeight: maxH,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Nivel de obesidad (estimado)',
                      style: Theme.of(ctx).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(nivel, style: Theme.of(ctx).textTheme.bodyLarge),
                    const SizedBox(height: 12),
                    Text(
                      'Confianza del modelo',
                      style: Theme.of(ctx).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pred.confianzaPorcentaje,
                      style: Theme.of(ctx).textTheme.bodyLarge,
                    ),
                    Text(
                      '(probabilidad softmax de la clase predicha)',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Dieta recomendada',
                      style: Theme.of(ctx).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(dieta, style: Theme.of(ctx).textTheme.bodyLarge),
                    const SizedBox(height: 20),
                    _BotonRealizarOtraConsultaPastel(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _resetForm();
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo calcular: $e')));
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoModelo) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: _kAccentGreen)),
      );
    }
    if (_errorModelo.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No se pudo cargar el modelo.\n$_errorModelo'),
        ),
      );
    }

    final catOpts = _predictor.categoricalOptions();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nueva consulta',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Paso ${_currentStep + 1} de $_totalPasos · ${_titulosPasos[_currentStep]}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B6B6F),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _BarraProgreso(paso: _currentStep, total: _totalPasos),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey<String>('${_currentStep}_$_nonceContenidoPaso'),
                    child: SingleChildScrollView(
                      controller: _scrollConsulta,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final col in _columnasPaso(_currentStep))
                            if (_campoPorColumna(col) != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: _buildCampo(
                                  _campoPorColumna(col)!,
                                  catOpts,
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _BarraAcciones(
                paso: _currentStep,
                totalPasos: _totalPasos,
                procesando: _procesando,
                onAtras: _currentStep > 0 ? _atras : null,
                onSiguiente: _currentStep < _totalPasos - 1 ? _siguiente : null,
                onRecomendar: _currentStep == _totalPasos - 1 ? _recomendar : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampo(_Campo c, Map<String, List<String>> catOpts) {
    if (c.esNumerica) {
      final orden = _columnasNumericasDelPaso(_currentStep);
      final ultimoNum =
          orden.isNotEmpty && orden.last == c.columna;
      return _CampoNumerico(
        campo: c,
        controller: _numericos[c.columna]!,
        focusNode: _focusNumericos[c.columna]!,
        icon: _iconoNumerico(c.columna),
        textInputAction:
            ultimoNum ? TextInputAction.done : TextInputAction.next,
        onAccionTeclado: () => _onNumericoAccionTeclado(c.columna),
      );
    }
    final opciones = catOpts[c.columna] ?? const [];
    if (c.columna == 'Genero') {
      return _SelectorGenero(
        etiqueta: c.etiqueta,
        valor: _categoricos[c.columna],
        onElegir: (v) => setState(() => _categoricos[c.columna] = v),
      );
    }
    if (_esSiNo(opciones)) {
      return _SelectorSiNo(
        etiqueta: c.etiqueta,
        columna: c.columna,
        valor: _categoricos[c.columna],
        onElegir: (v) => setState(() => _categoricos[c.columna] = v),
      );
    }
    if (c.columna == 'Medio_Transporte') {
      return _SelectorTransporte(
        etiqueta: c.etiqueta,
        opciones: opciones,
        valor: _categoricos[c.columna],
        onElegir: (v) => setState(() => _categoricos[c.columna] = v),
      );
    }
    return _SelectorTarjetas(
      etiqueta: c.etiqueta,
      opciones: opciones,
      valor: _categoricos[c.columna],
      onElegir: (v) => setState(() => _categoricos[c.columna] = v),
    );
  }
}

/// Botón del diálogo de resultado: verde pastel, perfil bajo y [RoundedRectangleBorder].
class _BotonRealizarOtraConsultaPastel extends StatelessWidget {
  const _BotonRealizarOtraConsultaPastel({required this.onPressed});

  final VoidCallback onPressed;

  static const _fill = Color(0xFFE8F5E9);
  static const _border = Color(0xFF81C784);
  static const _foreground = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 20),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: _fill,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: _border, width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: _foreground,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Realizar otra consulta',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: _foreground,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.15,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarraProgreso extends StatelessWidget {
  const _BarraProgreso({required this.paso, required this.total});

  final int paso;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraccion = (paso + 1) / total;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 8,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth * fraccion.clamp(0.0, 1.0);
            return Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: Colors.grey.shade200),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: w,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_kPastelGreenMid, _kAccentGreenDark],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CampoNumerico extends StatelessWidget {
  const _CampoNumerico({
    required this.campo,
    required this.controller,
    required this.focusNode,
    required this.icon,
    required this.textInputAction,
    required this.onAccionTeclado,
  });

  final _Campo campo;
  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData? icon;
  final TextInputAction textInputAction;
  final VoidCallback onAccionTeclado;

  @override
  Widget build(BuildContext context) {
    final relleno = controller.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          campo.etiqueta,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A3C),
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: textInputAction,
          onEditingComplete: onAccionTeclado,
          validator: (t) {
            final v = t?.trim().replaceAll(',', '.') ?? '';
            if (v.isEmpty) return 'Obligatorio';
            if (double.tryParse(v) == null) return 'Número inválido';
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: icon != null
                ? Icon(icon, color: const Color(0xFF757575), size: 22)
                : null,
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kInputRadius),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kInputRadius),
              borderSide: BorderSide(
                color: relleno ? _kPastelGreen : Colors.grey.shade300,
                width: relleno ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kInputRadius),
              borderSide: const BorderSide(color: _kAccentGreen, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kInputRadius),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kInputRadius),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectorGenero extends StatelessWidget {
  const _SelectorGenero({
    required this.etiqueta,
    required this.valor,
    required this.onElegir,
  });

  final String etiqueta;
  final String? valor;
  final ValueChanged<String> onElegir;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A3C),
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TarjetaSeleccion(
                seleccionada: valor == 'Masculino',
                onTap: () => onElegir('Masculino'),
                child: Column(
                  children: [
                    Icon(
                      Icons.male,
                      size: 44,
                      color: valor == 'Masculino'
                          ? _kAccentGreenDark
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Masculino',
                      style: TextStyle(
                        fontWeight: valor == 'Masculino'
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: const Color(0xFF3A3A3C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TarjetaSeleccion(
                seleccionada: valor == 'Femenino',
                onTap: () => onElegir('Femenino'),
                child: Column(
                  children: [
                    Icon(
                      Icons.female,
                      size: 44,
                      color: valor == 'Femenino'
                          ? _kAccentGreenDark
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Femenino',
                      style: TextStyle(
                        fontWeight: valor == 'Femenino'
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: const Color(0xFF3A3A3C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SelectorSiNo extends StatelessWidget {
  const _SelectorSiNo({
    required this.etiqueta,
    required this.columna,
    required this.valor,
    required this.onElegir,
  });

  final String etiqueta;
  final String columna;
  final String? valor;
  final ValueChanged<String> onElegir;

  @override
  Widget build(BuildContext context) {
    IconData icono = Icons.help_outline;
    if (columna.contains('Fumador')) {
      icono = Icons.smoking_rooms_outlined;
    } else if (columna.contains('Control')) {
      icono = Icons.balance_outlined;
    } else if (columna.contains('Antecedentes')) {
      icono = Icons.groups_outlined;
    } else if (columna.contains('Hipercalorico')) {
      icono = Icons.fastfood_outlined;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 20, color: const Color(0xFF757575)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                etiqueta,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A3C),
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TarjetaSeleccion(
                seleccionada: valor == 'si',
                onTap: () => onElegir('si'),
                child: const Text(
                  'Sí',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TarjetaSeleccion(
                seleccionada: valor == 'no',
                onTap: () => onElegir('no'),
                child: const Text(
                  'No',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SelectorTarjetas extends StatelessWidget {
  const _SelectorTarjetas({
    required this.etiqueta,
    required this.opciones,
    required this.valor,
    required this.onElegir,
  });

  final String etiqueta;
  final List<String> opciones;
  final String? valor;
  final ValueChanged<String> onElegir;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.touch_app_outlined,
                size: 20, color: Color(0xFF757575)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                etiqueta,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A3C),
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final op in opciones)
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 100),
                child: _TarjetaSeleccion(
                  seleccionada: valor == op,
                  onTap: () => onElegir(op),
                  child: Text(
                    op.replaceAll('_', ' '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SelectorTransporte extends StatelessWidget {
  const _SelectorTransporte({
    required this.etiqueta,
    required this.opciones,
    required this.valor,
    required this.onElegir,
  });

  final String etiqueta;
  final List<String> opciones;
  final String? valor;
  final ValueChanged<String> onElegir;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.commute, size: 20, color: Color(0xFF757575)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                etiqueta,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A3C),
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final op in opciones)
              SizedBox(
                width: 104,
                child: _TarjetaSeleccion(
                  seleccionada: valor == op,
                  onTap: () => onElegir(op),
                  child: Column(
                    children: [
                      Icon(
                        _iconoTransporte(op),
                        size: 30,
                        color: valor == op
                            ? _kAccentGreenDark
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        op.replaceAll('_', ' '),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TarjetaSeleccion extends StatelessWidget {
  const _TarjetaSeleccion({
    required this.seleccionada,
    required this.onTap,
    required this.child,
  });

  final bool seleccionada;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: seleccionada ? _kPastelGreenBg : Colors.white,
        borderRadius: BorderRadius.circular(_kInputRadius),
        border: Border.all(
          color: seleccionada ? _kAccentGreen : Colors.grey.shade300,
          width: seleccionada ? 2.5 : 1,
        ),
        boxShadow: [
          if (!seleccionada)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_kInputRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _BarraAcciones extends StatelessWidget {
  const _BarraAcciones({
    required this.paso,
    required this.totalPasos,
    required this.procesando,
    this.onAtras,
    this.onSiguiente,
    this.onRecomendar,
  });

  final int paso;
  final int totalPasos;
  final bool procesando;
  final VoidCallback? onAtras;
  final VoidCallback? onSiguiente;
  final VoidCallback? onRecomendar;

  @override
  Widget build(BuildContext context) {
    final ultimo = paso >= totalPasos - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onAtras != null)
            TextButton(
              onPressed: procesando ? null : onAtras,
              child: const Text('Atrás'),
            )
          else
            const SizedBox(width: 8),
          const Spacer(),
          if (!ultimo)
            _BotonGradiente(
              onPressed: procesando ? null : onSiguiente,
              icon: Icons.arrow_forward_rounded,
              label: 'Siguiente',
            )
          else
            _BotonGradiente(
              onPressed: procesando ? null : onRecomendar,
              icon: procesando ? null : Icons.restaurant_menu,
              label: procesando ? 'Calculando…' : 'Recomendar dieta',
              loading: procesando,
            ),
        ],
      ),
    );
  }
}

class _BotonGradiente extends StatelessWidget {
  const _BotonGradiente({
    required this.onPressed,
    required this.label,
    this.icon,
    this.loading = false,
    this.fullWidth = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final row = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment:
          fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        if (loading)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Colors.white,
            ),
          )
        else if (icon != null) ...[
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );
    final inner = Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kPastelGreenMid, _kAccentGreen, _kAccentGreenDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(_kInputRadius),
          boxShadow: [
            BoxShadow(
              color: _kAccentGreen.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(_kInputRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: row,
            ),
          ),
        ),
      ),
    );
    if (fullWidth) {
      return SizedBox(width: double.infinity, child: inner);
    }
    return inner;
  }
}
