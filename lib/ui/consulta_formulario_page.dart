import 'package:flutter/material.dart';

import '../domain/dieta_por_nivel.dart';
import '../ml/metabolic_predictor.dart';
import '../services/registro_consulta_firestore.dart';

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
    etiqueta: 'Número de comidas principales al día',
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
    etiqueta: 'Tiempo frente a pantallas (horas/día)',
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

class ConsultaFormularioPage extends StatefulWidget {
  const ConsultaFormularioPage({super.key});

  @override
  State<ConsultaFormularioPage> createState() => _ConsultaFormularioPageState();
}

class _ConsultaFormularioPageState extends State<ConsultaFormularioPage> {
  final _formKey = GlobalKey<FormState>();
  final _predictor = MetabolicPredictor.instance;
  final _repo = RegistroConsultaFirestore();

  final _numericos = <String, TextEditingController>{};
  final _categoricos = <String, String?>{};

  var _cargandoModelo = true;
  var _errorModelo = '';
  var _procesando = false;

  @override
  void initState() {
    super.initState();
    for (final c in _camposOrdenDataset) {
      if (c.esNumerica) {
        _numericos[c.columna] = TextEditingController();
      }
    }
    _inicializarModelo();
  }

  Future<void> _inicializarModelo() async {
    try {
      await _predictor.initialize();
      final opts = _predictor.categoricalOptions();
      if (mounted) {
        setState(() {
          for (final c in _camposOrdenDataset) {
            if (!c.esNumerica) {
              final lista = opts[c.columna];
              _categoricos[c.columna] = (lista != null && lista.isNotEmpty)
                  ? lista.first
                  : null;
            }
          }
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
    for (final t in _numericos.values) {
      t.dispose();
    }
    super.dispose();
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

  Future<void> _recomendar() async {
    if (_cargandoModelo || !_predictor.isReady) return;
    if (!_formKey.currentState!.validate()) return;

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
        builder: (ctx) => AlertDialog(
          title: const Text('Resultado'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
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
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorModelo.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text('No se pudo cargar el modelo.\n$_errorModelo'),
      );
    }

    final catOpts = _predictor.categoricalOptions();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Complete los mismos datos que en el estudio (dataset). '
            'Pulse el botón inferior para estimar el perfil y la dieta.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final c in _camposOrdenDataset) ...[
            if (c.esNumerica)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _numericos[c.columna],
                  decoration: InputDecoration(
                    labelText: c.etiqueta,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (t) {
                    final v = t?.trim().replaceAll(',', '.') ?? '';
                    if (v.isEmpty) return 'Obligatorio';
                    if (double.tryParse(v) == null) return 'Número inválido';
                    return null;
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  key: ValueKey('${c.columna}_${_categoricos[c.columna]}'),
                  initialValue: _categoricos[c.columna],
                  decoration: InputDecoration(
                    labelText: c.etiqueta,
                    border: const OutlineInputBorder(),
                  ),
                  items: (catOpts[c.columna] ?? const <String>[])
                      .map(
                        (v) =>
                            DropdownMenuItem<String>(value: v, child: Text(v)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _categoricos[c.columna] = v),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Seleccione una opción' : null,
                ),
              ),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _procesando ? null : _recomendar,
            icon: _procesando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.restaurant_menu),
            label: Text(_procesando ? 'Calculando…' : 'Recomendar dieta'),
          ),
        ],
      ),
    );
  }
}
