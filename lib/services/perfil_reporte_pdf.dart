import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart'
    show PlatformException, rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../theme/dietwise_theme.dart';

/// Acentos pastel (referencia visual tipo panel: verde, azul, púrpura).
final PdfColor _kAccentGreen = PdfColor.fromInt(0xFF81C784);
final PdfColor _kAccentBlue = PdfColor.fromInt(0xFF64B5F6);
final PdfColor _kAccentPurple = PdfColor.fromInt(0xFF9575CD);

final PdfColor _kCardFill = PdfColor.fromInt(0xFFFAFAFA);

/// Borde exterior suave alineado con identidad DietWise (púrpura pastel).
final PdfColor _kBordePrincipal = PdfColors.purple100;

/// Márgenes generosos (≈40 pt en PDF).
const double _kMargin = 40;

const double _kFontTituloDoc = 11;
const double _kFontSeccion = 9.5;
const double _kFontCuerpo = 9;
const double _kFontMini = 7.5;
const double _kFontPie = 7.5;

const double _kEntreTarjetas = 15;
const double _kEspFinal = 32;

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

pw.Widget _marcaIcono(PdfColor color) {
  return pw.Container(
    width: 6,
    height: 6,
    decoration: pw.BoxDecoration(
      color: color,
      shape: pw.BoxShape.circle,
    ),
  );
}

pw.BoxDecoration _decorTarjetaPrincipal() {
  return pw.BoxDecoration(
    color: _kCardFill,
    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15)),
    border: pw.Border.all(
      color: _kBordePrincipal,
      width: 1.5,
    ),
    boxShadow: [
      pw.BoxShadow(
        color: PdfColors.grey400,
        blurRadius: 3,
        spreadRadius: 0.5,
        offset: const PdfPoint(0, 1.2),
      ),
    ],
  );
}

/// Mini-tarjetas dentro de «Resumen de actividad» (IMC / consultas).
pw.BoxDecoration _decorMiniActividad({required PdfColor acentoBorde}) {
  return pw.BoxDecoration(
    color: PdfColors.white,
    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
    border: pw.Border.all(color: acentoBorde, width: 1.1),
    boxShadow: [
      pw.BoxShadow(
        color: PdfColors.grey300,
        blurRadius: 2,
        spreadRadius: 0.25,
        offset: const PdfPoint(0, 1),
      ),
    ],
  );
}

pw.Widget _filaDatoCentrada(
  String etiqueta,
  String valor,
  PdfColor acento,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            _marcaIcono(acento),
            pw.SizedBox(width: 6),
            pw.Text(
              etiqueta.toUpperCase(),
              style: pw.TextStyle(
                fontSize: _kFontMini,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          valor.isEmpty ? '—' : valor,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: _kFontCuerpo,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey900,
          ),
          maxLines: 2,
        ),
      ],
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: _decorMiniActividad(acentoBorde: acento),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            titulo,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: _kFontMini - 0.5,
              fontWeight: pw.FontWeight.bold,
              color: acento,
            ),
            maxLines: 3,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            valor,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: _kFontCuerpo + 0.5,
              fontWeight: pw.FontWeight.bold,
            ),
            maxLines: 2,
          ),
        ],
      ),
    ),
  );
}

Map<String, String> _estrategiaNutricionalFilas(String? dietaNombre) {
  final d = (dietaNombre ?? '').toLowerCase();
  if (d.contains('hipercal')) {
    return {
      'cal': 'Superávit moderado',
      'macro': 'CH 50–55 % · Prot. 15–20 % · Grasas 25–30 %',
      'sup': 'Multivitamínico prudente; vit. D según analítica',
      'obs': 'Priorizar alimentos densos en nutrientes; vigilancia médica.',
    };
  }
  if (d.contains('muy baja') || d.contains('hipocal')) {
    return {
      'cal': 'Déficit controlado',
      'macro': 'Prot. 25–30 % · CH moderados · Fibra alta',
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
      'macro': 'Prot. elevada · CH bajo–moderado · Grasas saludables',
      'sup': 'Electrolitos si dieta muy baja en CH; consultar profesional',
      'obs': 'Control renal/hepático si la proteína es muy alta.',
    };
  }
  return {
    'cal': 'Equilibrio energético',
    'macro': 'Plato mixto: ½ vegetales, ¼ integral, ¼ proteína',
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
          final anchoContenido = context.page.pageFormat.availableWidth;

          final avatar = pw.Container(
            width: 58,
            height: 58,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: _kAccentGreen, width: 2.2),
            ),
            child: pw.ClipOval(
              child: fotoPerfilBytes != null && fotoPerfilBytes.isNotEmpty
                  ? pw.Image(
                      pw.MemoryImage(fotoPerfilBytes),
                      fit: pw.BoxFit.cover,
                      width: 58,
                      height: 58,
                    )
                  : pw.Container(
                      color: PdfColor.fromInt(0xFFE8F5E9),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'DW',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: _kAccentGreen,
                        ),
                      ),
                    ),
            ),
          );

          return pw.Center(
            child: pw.SizedBox(
              width: anchoContenido,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoBytes != null)
                    pw.Image(
                      pw.MemoryImage(logoBytes),
                      width: 92,
                      height: 92,
                      fit: pw.BoxFit.contain,
                    ),
                  if (logoBytes != null) pw.SizedBox(height: 10),
                  pw.Text(
                    'REPORTE NUTRICIONAL DE DIETAWISE - DIAGNÓSTICO INTEGRAL',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: _kFontTituloDoc,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                      letterSpacing: 0.2,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generado: $fecha',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: _kFontMini,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: _kEntreTarjetas),

                  // —— Tarjeta: Perfil del usuario ——
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(14),
                    decoration: _decorTarjetaPrincipal(),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'PERFIL DEL USUARIO',
                          style: pw.TextStyle(
                            fontSize: _kFontSeccion,
                            fontWeight: pw.FontWeight.bold,
                            color: _kAccentGreen,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        avatar,
                        pw.SizedBox(height: 12),
                        _filaDatoCentrada(
                          'Nombre completo',
                          nombreCompleto.isEmpty ? '—' : nombreCompleto,
                          _kAccentGreen,
                        ),
                        _filaDatoCentrada('Edad', '$edadStr años', _kAccentBlue),
                        _filaDatoCentrada(
                          'Altura (cm)',
                          altCm,
                          _kAccentPurple,
                        ),
                        _filaDatoCentrada('Peso (kg)', pesoStr, _kAccentGreen),
                        if (email.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            email,
                            textAlign: pw.TextAlign.center,
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
                  pw.SizedBox(height: _kEntreTarjetas),

                  // —— Tarjeta: Resumen de actividad ——
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: _decorTarjetaPrincipal(),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'RESUMEN DE ACTIVIDAD',
                          style: pw.TextStyle(
                            fontSize: _kFontSeccion,
                            fontWeight: pw.FontWeight.bold,
                            color: _kAccentBlue,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _miniTarjetaActividad(
                              acento: _kAccentGreen,
                              titulo:
                                  'ÍNDICE DE\nMASA CORPORAL',
                              valor: _imcTexto(imc),
                            ),
                            pw.SizedBox(width: 12),
                            _miniTarjetaActividad(
                              acento: _kAccentBlue,
                              titulo:
                                  'CONSULTAS\nREALIZADAS',
                              valor: consultasTxt,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: _kEntreTarjetas),

                  // —— Último diagnóstico ——
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: _decorTarjetaPrincipal(),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'ÚLTIMO DIAGNÓSTICO',
                          style: pw.TextStyle(
                            fontSize: _kFontSeccion,
                            fontWeight: pw.FontWeight.bold,
                            color: _kAccentPurple,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        if (ultimaConsulta == null)
                          pw.Text(
                            'Sin consultas registradas en la cuenta.',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(fontSize: _kFontCuerpo),
                          )
                        else ...[
                          pw.Text(
                            'Evaluación: ${_nivelLegible(nivel)}',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: _kFontCuerpo,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Plan asociado: ${dieta ?? '—'}',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(fontSize: _kFontCuerpo),
                            maxLines: 2,
                          ),
                          if (conf is num) ...[
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Confianza del modelo: ${(conf.toDouble() * 100).toStringAsFixed(1)} %',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: _kFontMini,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(height: _kEntreTarjetas),

                  // —— Resumen última consulta (sustituye plan semanal) ——
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: _decorTarjetaPrincipal(),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'RESUMEN DE ÚLTIMA CONSULTA',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: _kFontSeccion,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey900,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Puntos clave de la sesión',
                          style: pw.TextStyle(
                            fontSize: _kFontMini,
                            fontWeight: pw.FontWeight.bold,
                            color: _kAccentBlue,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: pw.WrapAlignment.center,
                          children: puntos.map((p) {
                            return pw.Container(
                              width: (anchoContenido - 8) / 2,
                              padding: const pw.EdgeInsets.all(6),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.white,
                                borderRadius:
                                    pw.BorderRadius.circular(8),
                                border: pw.Border.all(
                                  color: PdfColors.purple50,
                                  width: 0.75,
                                ),
                              ),
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _marcaIcono(_kAccentPurple),
                                  pw.SizedBox(width: 6),
                                  pw.Expanded(
                                    child: pw.Text(
                                      p,
                                      style: pw.TextStyle(
                                        fontSize: _kFontMini,
                                        height: 1.2,
                                      ),
                                      maxLines: 4,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'Estrategia nutricional actual',
                          style: pw.TextStyle(
                            fontSize: _kFontMini,
                            fontWeight: pw.FontWeight.bold,
                            color: _kAccentGreen,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Table(
                          border: pw.TableBorder.all(
                            color: PdfColors.purple50,
                            width: 0.55,
                          ),
                          columnWidths: {
                            0: const pw.FlexColumnWidth(1.1),
                            1: const pw.FlexColumnWidth(1.35),
                            2: const pw.FlexColumnWidth(1.0),
                            3: const pw.FlexColumnWidth(1.15),
                          },
                          children: [
                            pw.TableRow(
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromInt(0xFFF3E5F5),
                              ),
                              children: [
                                _th('Ajuste calórico'),
                                _th('Equilibrio de macronutrientes'),
                                _th('Suplementos recomendados'),
                                _th('Observaciones'),
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
                      ],
                    ),
                  ),

                  pw.SizedBox(height: _kEspFinal),

                  pw.Text(
                    'Políticas de seguridad y Términos y condiciones: consulte el texto legal completo en la aplicación DietWise.',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: _kFontPie,
                      color: PdfColors.grey600,
                    ),
                    maxLines: 2,
                  ),
                  pw.SizedBox(height: 3),
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
              ),
            ),
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

  static pw.Widget _th(String s) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        s,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: _kFontMini - 0.5,
          fontWeight: pw.FontWeight.bold,
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
    try {
      final data = await rootBundle.load(DietWiseColors.logoCompletoAsset);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
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
