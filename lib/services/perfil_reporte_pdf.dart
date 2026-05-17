import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart'
    show PlatformException, rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Identidad DietWise en PDF.
final PdfColor _kMorado = PdfColor.fromInt(0xFF7B1FA2);
final PdfColor _kBordeGris = PdfColor.fromInt(0xFFE2E8F0);
final PdfColor _kFondoEtiqueta = PdfColor.fromInt(0xFFF7FAFC);
final PdfColor _kAccentGreen = PdfColor.fromInt(0xFF81C784);
final PdfColor _kAccentBlue = PdfColor.fromInt(0xFF64B5F6);

const double _kMargin = 28;

const double _kFontMarca = 14;
const double _kFontSeccion = 8.5;
const double _kFontCuerpo = 8;
const double _kFontMini = 7;
const double _kFontPie = 6.5;

const double _kEspSeccion = 7;
const double _kEspFinal = 10;

const String _kLogoAsset = 'assets/logo/logo.png';
const String _kLogoFallback = 'assets/logo/logocompleto.png';

String _nivelLegible(Object? v) {
  if (v == null) return '—';
  return '$v'.replaceAll('_', ' ');
}

String _fechaReporte() {
  final d = DateTime.now();
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '${d.day}/${d.month}/${d.year} $h:$m';
}

/// Altura del perfil en metros → cm para el PDF.
String _alturaCmTexto(double? alturaM) {
  if (alturaM == null) return '—';
  if (alturaM > 0 && alturaM < 4) {
    return '${(alturaM * 100).round()}';
  }
  return '${alturaM.round()}';
}

String _imcTexto(double? imc) {
  if (imc == null) return '—';
  return imc.toStringAsFixed(1);
}

pw.Widget _tituloSeccion(String titulo) {
  return pw.Container(
    width: double.infinity,
    margin: const pw.EdgeInsets.only(bottom: 5),
    padding: const pw.EdgeInsets.only(left: 8, top: 2, bottom: 2),
    decoration: pw.BoxDecoration(
      border: pw.Border(
        left: pw.BorderSide(color: _kMorado, width: 3.5),
      ),
    ),
    child: pw.Text(
      titulo.toUpperCase(),
      style: pw.TextStyle(
        fontSize: _kFontSeccion,
        fontWeight: pw.FontWeight.bold,
        color: _kMorado,
        letterSpacing: 0.3,
      ),
    ),
  );
}

pw.Widget _encabezadoInstitucional({
  required Uint8List? logoBytes,
  required String fecha,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logoBytes != null)
            pw.Image(
              pw.MemoryImage(logoBytes),
              width: 35,
              height: 35,
              fit: pw.BoxFit.contain,
            ),
          if (logoBytes != null) pw.SizedBox(width: 8),
          pw.Text(
            'DietWise',
            style: pw.TextStyle(
              fontSize: _kFontMarca,
              fontWeight: pw.FontWeight.bold,
              color: _kMorado,
            ),
          ),
          pw.Spacer(),
          pw.Text(
            'REPORTE NUTRICIONAL',
            style: pw.TextStyle(
              fontSize: _kFontSeccion,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 3),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Generado: $fecha',
          style: pw.TextStyle(
            fontSize: _kFontMini,
            color: PdfColors.grey600,
          ),
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Container(height: 1.2, color: _kMorado),
      pw.SizedBox(height: _kEspSeccion),
    ],
  );
}

pw.Widget _celdaEtiqueta(String texto) {
  return pw.Container(
    color: _kFondoEtiqueta,
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: pw.Text(
      texto,
      style: pw.TextStyle(
        fontSize: _kFontMini,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey800,
      ),
    ),
  );
}

pw.Widget _celdaValor(String texto) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: pw.Text(
      texto.isEmpty ? '—' : texto,
      style: pw.TextStyle(fontSize: _kFontMini, color: PdfColors.grey900),
      maxLines: 2,
    ),
  );
}

pw.TableRow _filaTablaDatos(String etiqueta, String valor) {
  return pw.TableRow(
    children: [
      _celdaEtiqueta(etiqueta),
      _celdaValor(valor),
    ],
  );
}

pw.Widget _tablaDatosPersonales(List<pw.TableRow> filas) {
  return pw.Table(
    border: pw.TableBorder.all(color: _kBordeGris, width: 0.5),
    columnWidths: {
      0: const pw.FlexColumnWidth(1.05),
      1: const pw.FlexColumnWidth(1.35),
    },
    children: filas,
  );
}

pw.Widget _fotoPerfilPdf(Uint8List? fotoPerfilBytes) {
  const tam = 68.0;
  return pw.Container(
    width: tam,
    height: tam,
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFEEEEEE),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      border: pw.Border.all(color: _kBordeGris, width: 0.8),
    ),
    child: fotoPerfilBytes != null && fotoPerfilBytes.isNotEmpty
        ? pw.ClipRRect(
            horizontalRadius: 10,
            verticalRadius: 10,
            child: pw.Image(
              pw.MemoryImage(fotoPerfilBytes),
              width: tam,
              height: tam,
              fit: pw.BoxFit.cover,
            ),
          )
        : pw.Center(
            child: pw.Text(
              'U',
              style: pw.TextStyle(
                fontSize: 26,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey500,
              ),
            ),
          ),
  );
}

pw.Widget _miniTarjetaActividad({
  required PdfColor acento,
  required String titulo,
  required String valor,
}) {
  return pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: acento, width: 0.9),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            titulo,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: _kFontMini,
              fontWeight: pw.FontWeight.bold,
              color: acento,
            ),
            maxLines: 2,
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            valor,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: _kFontCuerpo,
              fontWeight: pw.FontWeight.bold,
            ),
            maxLines: 1,
          ),
        ],
      ),
    ),
  );
}

pw.Widget _contenedorRecomendaciones(List<String> puntos) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      border: pw.Border.all(color: _kBordeGris, width: 0.6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: puntos
          .map(
            (p) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '- ',
                    style: pw.TextStyle(
                      fontSize: _kFontMini,
                      color: _kMorado,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      p,
                      style: pw.TextStyle(
                        fontSize: _kFontMini,
                        height: 1.3,
                        color: PdfColors.grey800,
                      ),
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );
}

Map<String, String> _estrategiaNutricionalFilas(String? dietaNombre) {
  final d = (dietaNombre ?? '').toLowerCase();
  if (d.contains('hipercal')) {
    return {
      'cal': 'Superávit moderado',
      'macro': 'CH 50-55 %, Prot. 15-20 %, Grasas 25-30 %',
      'sup': 'Multivitamínico prudente; vit. D según analítica',
      'obs': 'Priorizar alimentos densos en nutrientes; vigilancia médica.',
    };
  }
  if (d.contains('muy baja') || d.contains('hipocal')) {
    return {
      'cal': 'Déficit controlado',
      'macro': 'Prot. 25-30 %, CH moderados, Fibra alta',
      'sup': 'Complejo B si restricción prolongada; valorar vit. D',
      'obs': 'Distribuir tomas; hidratación y actividad supervisada.',
    };
  }
  if (d.contains('glucémico')) {
    return {
      'cal': 'Mantenimiento o leve déficit',
      'macro': 'Prioridad fibra y proteína; CH integrales repartidos',
      'sup': 'Magnesio / omega-3 solo si indicación profesional',
      'obs': 'Evitar picos glucémicos; registrar respuesta a comidas.',
    };
  }
  if (d.contains('proteín')) {
    return {
      'cal': 'Déficit suave a moderado',
      'macro': 'Prot. elevada, CH bajo-moderado, Grasas saludables',
      'sup': 'Electrolitos si dieta muy baja en CH; consultar profesional',
      'obs': 'Control renal/hepático si la proteína es muy alta.',
    };
  }
  return {
    'cal': 'Equilibrio energético',
    'macro': 'Plato mixto: 1/2 vegetales, 1/4 integral, 1/4 proteina',
    'sup': 'Ninguno obligatorio; solo según prescripción',
    'obs': 'Ajustar porciones a actividad y objetivos clínicos.',
  };
}

List<String> _puntosSesion({
  required Object? nivel,
  required String? dieta,
}) {
  final n = _nivelLegible(nivel);
  final plan = dieta?.isNotEmpty == true ? dieta! : 'Sin plan registrado';
  return <String>[
    'Estado general: clasificación $n; sesión basada en formulario y modelo IA.',
    'Metas logradas: registro de consulta y recomendación dietética asociada ($plan).',
    'Desafíos: adherencia al plan, control de porciones y hábitos sedentarios.',
    'Objetivos: seguimiento del plan indicado y revisión periódica con profesional de salud.',
  ];
}

/// Resultado de exportar el reporte a disco (o descarga en web).
enum PerfilReportePdfResultado {
  cancelado,

  guardado,

  error,
}

/// Comprobación previa a exportar (perfil Firestore + historial de consultas).
enum PerfilReporteElegibilidadExportacion {
  listo,
  perfilIncompleto,
  sinConsultas,
}

class PerfilReportePdf {
  PerfilReportePdf._();

  static const String mensajePerfilIncompleto =
      'Para exportar tu reporte, primero debes completar todos los datos '
      'biométricos en tu perfil.';

  static const String mensajeSinConsultas =
      'Aún no tienes un diagnóstico disponible. Por favor, realiza al menos '
      'una consulta nutricional antes de exportar.';

  /// Valida documento `usuarios/{uid}` y conteo en `registros_consulta`.
  static PerfilReporteElegibilidadExportacion evaluarElegibilidadExportacion({
    required Map<String, dynamic>? perfilFirestore,
    required int numConsultasFirestore,
  }) {
    if (!perfilBiometricoCompleto(perfilFirestore)) {
      return PerfilReporteElegibilidadExportacion.perfilIncompleto;
    }
    if (numConsultasFirestore < 1) {
      return PerfilReporteElegibilidadExportacion.sinConsultas;
    }
    return PerfilReporteElegibilidadExportacion.listo;
  }

  /// `nombre`, `apellido`, `edad`, `altura` y `peso` en Firestore, sin vacíos ni cero.
  static bool perfilBiometricoCompleto(Map<String, dynamic>? perfil) {
    if (perfil == null) return false;
    if (!_textoNoVacio(perfil['nombre'])) return false;
    if (!_textoNoVacio(perfil['apellido'])) return false;
    if (!_enteroPositivo(perfil['edad'])) return false;
    if (!_numeroPositivo(perfil['altura'])) return false;
    if (!_numeroPositivo(perfil['peso'])) return false;
    return true;
  }

  static bool _textoNoVacio(Object? valor) {
    if (valor == null) return false;
    return valor.toString().trim().isNotEmpty;
  }

  static bool _enteroPositivo(Object? valor) {
    if (valor == null) return false;
    final n = valor is int ? valor : int.tryParse(valor.toString().trim());
    return n != null && n > 0;
  }

  static bool _numeroPositivo(Object? valor) {
    if (valor == null) return false;
    final n = valor is num
        ? valor.toDouble()
        : double.tryParse(valor.toString().trim().replaceAll(',', '.'));
    return n != null && n > 0;
  }

  /// Una sola página A4, maquetación centrada y tarjetas.
  static Future<PerfilReportePdfResultado> generarYPrevisualizar({
    required Uint8List? fotoPerfilBytes,
    required String nombre,
    required String apellido,
    required String email,
    int? edad,
    double? altura,
    double? peso,
    Map<String, Object?>? ultimaConsulta,
    required int numConsultas,
    double? imc,
  }) async {
    final logoBytes = await _cargarLogo();
    final fecha = _fechaReporte();

    final nivel = ultimaConsulta?['nivelObesidad'];
    final dieta = ultimaConsulta?['dietaRecomendada']?.toString();
    final conf = ultimaConsulta?['confianzaPrediccion'];

    final nombreCompleto = '$nombre $apellido'.trim();
    final edadStr = edad != null ? '$edad' : '—';
    final pesoStr = peso != null ? '$peso' : '—';
    final altCm = _alturaCmTexto(altura);
    final consultasTxt =
        numConsultas == 0 ? '0' : (numConsultas == 1 ? '1' : '$numConsultas');

    final theme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );

    final estrategia = _estrategiaNutricionalFilas(dieta);
    final puntos = _puntosSesion(
      nivel: nivel,
      dieta: dieta,
    );

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_kMargin),
        theme: theme,
        build: (context) {
          final filasPerfil = <pw.TableRow>[
            _filaTablaDatos(
              'Nombre completo',
              nombreCompleto.isEmpty ? '—' : nombreCompleto,
            ),
            _filaTablaDatos('Edad', '$edadStr años'),
            _filaTablaDatos('Altura (cm)', altCm),
            _filaTablaDatos('Peso (kg)', pesoStr),
          ];

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _encabezadoInstitucional(logoBytes: logoBytes, fecha: fecha),

              _tituloSeccion('PERFIL DEL USUARIO'),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        _tablaDatosPersonales(filasPerfil),
                        if (email.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            email,
                            style: pw.TextStyle(
                              fontSize: _kFontMini,
                              color: PdfColors.grey600,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  _fotoPerfilPdf(fotoPerfilBytes),
                ],
              ),
              pw.SizedBox(height: _kEspSeccion),

              _tituloSeccion('RESUMEN DE ACTIVIDAD'),
              pw.Row(
                children: [
                  _miniTarjetaActividad(
                    acento: _kAccentGreen,
                    titulo: 'ÍNDICE DE\nMASA CORPORAL',
                    valor: _imcTexto(imc),
                  ),
                  pw.SizedBox(width: 8),
                  _miniTarjetaActividad(
                    acento: _kAccentBlue,
                    titulo: 'CONSULTAS\nREALIZADAS',
                    valor: consultasTxt,
                  ),
                ],
              ),
              pw.SizedBox(height: _kEspSeccion),

              _tituloSeccion('ÚLTIMO DIAGNÓSTICO'),
              if (ultimaConsulta == null)
                pw.Text(
                  'Sin consultas registradas en la cuenta.',
                  style: pw.TextStyle(fontSize: _kFontCuerpo),
                )
              else ...[
                pw.Text(
                  'Evaluación: ${_nivelLegible(nivel)}',
                  style: pw.TextStyle(
                    fontSize: _kFontCuerpo,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Plan asociado: ${dieta ?? '—'}',
                  style: pw.TextStyle(fontSize: _kFontCuerpo),
                  maxLines: 2,
                ),
                if (conf is num) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Confianza del modelo: ${(conf.toDouble() * 100).toStringAsFixed(1)} %',
                    style: pw.TextStyle(
                      fontSize: _kFontMini,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ],
              pw.SizedBox(height: _kEspSeccion),

              _tituloSeccion('RESUMEN DE ÚLTIMA CONSULTA'),
              pw.Text(
                'Puntos clave de la sesión',
                style: pw.TextStyle(
                  fontSize: _kFontMini,
                  fontWeight: pw.FontWeight.bold,
                  color: _kAccentBlue,
                ),
              ),
              pw.SizedBox(height: 4),
              _contenedorRecomendaciones(puntos),
              pw.SizedBox(height: 6),
              pw.Text(
                'Estrategia nutricional actual',
                style: pw.TextStyle(
                  fontSize: _kFontMini,
                  fontWeight: pw.FontWeight.bold,
                  color: _kAccentGreen,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: _kBordeGris, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.1),
                  1: const pw.FlexColumnWidth(1.35),
                  2: const pw.FlexColumnWidth(1.0),
                  3: const pw.FlexColumnWidth(1.15),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: _kMorado),
                    children: [
                      _thMorado('Ajuste calórico'),
                      _thMorado('Equilibrio de macronutrientes'),
                      _thMorado('Suplementos recomendados'),
                      _thMorado('Observaciones'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _td(estrategia['cal']!),
                      _td(estrategia['macro']!),
                      _td(estrategia['sup']!),
                      _td(estrategia['obs']!),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),
              pw.Text(
                'Políticas de seguridad y Términos y condiciones: consulte el texto legal completo en la aplicación DietWise.',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: _kFontPie,
                  color: PdfColors.grey600,
                ),
                maxLines: 2,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Documento informativo; no sustituye el consejo médico ni la consulta presencial con un profesional de la salud.',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: _kFontPie,
                  color: PdfColors.grey600,
                ),
                maxLines: 2,
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    const nombreDefault = 'DietWise_reporte.pdf';

    try {
      final outputPath = await FilePicker.saveFile(
        dialogTitle: 'Guardar Reporte Nutricional',
        fileName: nombreDefault,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        bytes: pdfBytes,
      );

      if (kIsWeb) {
        return PerfilReportePdfResultado.guardado;
      }

      if (outputPath == null || outputPath.isEmpty) {
        return PerfilReportePdfResultado.cancelado;
      }

      return PerfilReportePdfResultado.guardado;
    } on PlatformException {
      return PerfilReportePdfResultado.error;
    } catch (_) {
      return PerfilReportePdfResultado.error;
    }
  }

  static pw.Widget _thMorado(String s) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        s,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: _kFontMini - 0.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        maxLines: 3,
      ),
    );
  }

  static pw.Widget _td(String s) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        s,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: _kFontMini - 0.5, height: 1.15),
        maxLines: 5,
      ),
    );
  }

  static Future<Uint8List?> _cargarLogo() async {
    for (final path in [_kLogoAsset, _kLogoFallback]) {
      try {
        final data = await rootBundle.load(path);
        return data.buffer.asUint8List();
      } catch (_) {}
    }
    return null;
  }

  static Uint8List? bytesDesdeBase64(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    try {
      return Uint8List.fromList(base64Decode(b64));
    } catch (_) {
      return null;
    }
  }
}
