import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../domain/prediccion_metabolica.dart';

class _PreprocessorConfig {
  _PreprocessorConfig({
    required this.numericFeatures,
    required this.numericMeans,
    required this.numericScales,
    required this.categoricalFeatures,
    required this.categoricalCategories,
    required this.labelClasses,
    required this.inputSize,
  });

  final List<String> numericFeatures;
  final List<double> numericMeans;
  final List<double> numericScales;
  final List<String> categoricalFeatures;
  final List<List<String>> categoricalCategories;
  final List<String> labelClasses;
  final int inputSize;

  factory _PreprocessorConfig.fromJson(Map<String, dynamic> j) {
    return _PreprocessorConfig(
      numericFeatures: List<String>.from(j['numeric_features'] as List),
      numericMeans: (j['numeric_means'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      numericScales: (j['numeric_scales'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      categoricalFeatures: List<String>.from(j['categorical_features'] as List),
      categoricalCategories: (j['categorical_categories'] as List)
          .map((e) => List<String>.from((e as List).map((x) => '$x')))
          .toList(),
      labelClasses: List<String>.from(j['label_classes'] as List),
      inputSize: (j['input_size'] as num).toInt(),
    );
  }
}

/// Carga TFLite + JSON del preprocesador (mismo esquema que el entrenamiento en Python).
class MetabolicPredictor {
  MetabolicPredictor._();

  static final MetabolicPredictor instance = MetabolicPredictor._();

  Interpreter? _interpreter;
  _PreprocessorConfig? _cfg;

  bool get isReady => _interpreter != null && _cfg != null;

  Future<void> initialize() async {
    if (isReady) return;

    final jsonStr = await rootBundle.loadString('assets/ml_preprocessor.json');
    _cfg = _PreprocessorConfig.fromJson(
      json.decode(jsonStr) as Map<String, dynamic>,
    );

    _interpreter = await Interpreter.fromAsset(
      'assets/modelo_diagnostico_metabolico.tflite',
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _cfg = null;
  }

  List<double> buildFeatureVector({
    required Map<String, double> numericByName,
    required Map<String, String> categoricalByName,
  }) {
    final cfg = _cfg!;
    final out = <double>[];

    for (var i = 0; i < cfg.numericFeatures.length; i++) {
      final name = cfg.numericFeatures[i];
      final v = numericByName[name];
      if (v == null) {
        throw ArgumentError('Falta variable numérica: $name');
      }
      out.add((v - cfg.numericMeans[i]) / cfg.numericScales[i]);
    }

    for (var j = 0; j < cfg.categoricalFeatures.length; j++) {
      final name = cfg.categoricalFeatures[j];
      final val = categoricalByName[name];
      if (val == null) {
        throw ArgumentError('Falta variable categórica: $name');
      }
      final cats = cfg.categoricalCategories[j];
      final present = cats.contains(val);
      for (final c in cats) {
        out.add(present && val == c ? 1.0 : 0.0);
      }
    }

    if (out.length != cfg.inputSize) {
      throw StateError(
        'Tamaño de vector ${out.length} != esperado ${cfg.inputSize}',
      );
    }
    return out;
  }

  /// Clasificación multiclase + confianza (probabilidad softmax de la clase predicha).
  PrediccionMetabolica clasificar({
    required Map<String, double> numericByName,
    required Map<String, String> categoricalByName,
  }) {
    final cfg = _cfg!;
    final interpreter = _interpreter!;
    final vec = buildFeatureVector(
      numericByName: numericByName,
      categoricalByName: categoricalByName,
    );

    final input = [vec];
    final output = [List<double>.filled(cfg.labelClasses.length, 0)];
    interpreter.run(input, output);

    final scores = output[0];
    var best = 0;
    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > scores[best]) best = i;
    }
    final p = scores[best].clamp(0.0, 1.0);
    return PrediccionMetabolica(
      nivelObesidad: cfg.labelClasses[best],
      confianza: p,
    );
  }

  /// Solo la etiqueta predicha (equivale a [clasificar] y tomar [PrediccionMetabolica.nivelObesidad]).
  String predictNivelObesidad({
    required Map<String, double> numericByName,
    required Map<String, String> categoricalByName,
  }) {
    return clasificar(
      numericByName: numericByName,
      categoricalByName: categoricalByName,
    ).nivelObesidad;
  }

  /// Opciones de UI por variable categórica (orden del entrenamiento).
  Map<String, List<String>> categoricalOptions() {
    final cfg = _cfg!;
    return {
      for (var i = 0; i < cfg.categoricalFeatures.length; i++)
        cfg.categoricalFeatures[i]: List<String>.from(
          cfg.categoricalCategories[i],
        ),
    };
  }
}
