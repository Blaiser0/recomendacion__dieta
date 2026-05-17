import 'package:flutter/material.dart';

import '../services/registro_consulta_firestore.dart';

/// Misma línea que la tarjeta «Historial» del dashboard.
const _kPastelBlueBg = Color(0xFFE3F2FD);
const _kAccentBlue = Color(0xFF1565C0);
const _kBlueLight = Color(0xFF64B5F6);
const _kPageBg = Color(0xFFF5F7FA);
const _kCardRadius = 20.0;

/// Orden y etiquetas para el desglose (coinciden con `datosEntrada` de Firestore).
const _ordenCamposDetalle = <String>[
  'Genero',
  'Edad',
  'Altura',
  'Peso',
  'Antecedentes_Familiares',
  'Consumo_Hipercalorico',
  'Consumo_Verduras',
  'Comidas_Diarias',
  'Picoteo_Entre_Comidas',
  'Fumador',
  'Consumo_Agua',
  'Control_Calórico',
  'Actividad_Física',
  'Sedentarismo_Digital',
  'Consumo_Alcohol',
  'Medio_Transporte',
];

const _etiquetasCampo = <String, String>{
  'Genero': 'Género',
  'Edad': 'Edad (años)',
  'Altura': 'Altura (m)',
  'Peso': 'Peso (kg)',
  'Antecedentes_Familiares': 'Antecedentes familiares',
  'Consumo_Hipercalorico': 'Consumo hipercalórico',
  'Consumo_Verduras': 'Verduras (porciones/día)',
  'Comidas_Diarias': 'Comidas al día',
  'Picoteo_Entre_Comidas': 'Picoteo entre comidas',
  'Fumador': 'Fumador',
  'Consumo_Agua': 'Agua (L/día)',
  'Control_Calórico': 'Control calórico',
  'Actividad_Física': 'Actividad física',
  'Sedentarismo_Digital': 'Sedentarismo digital',
  'Consumo_Alcohol': 'Consumo alcohol',
  'Medio_Transporte': 'Transporte',
};

String _nivelLegible(String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  return raw.replaceAll('_', ' ');
}

String _valorLegible(Object? v) {
  if (v == null) return '—';
  return '$v'.replaceAll('_', ' ');
}

DateTime? _parsearCreado(Object? raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is String) {
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }
  return null;
}

String _formatoHora(DateTime d) {
  final h24 = d.hour;
  final m = d.minute.toString().padLeft(2, '0');
  final pm = h24 >= 12;
  final h12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
  return '$h12:$m ${pm ? 'p. m.' : 'a. m.'}';
}

String _formatoFechaHumana(Object? raw) {
  final d = _parsearCreado(raw);
  if (d == null) return 'Fecha no disponible';

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dDay = DateTime(d.year, d.month, d.day);
  final yesterday = today.subtract(const Duration(days: 1));

  if (dDay == today) {
    return 'Hoy, ${_formatoHora(d)}';
  }
  if (dDay == yesterday) {
    return 'Ayer, ${_formatoHora(d)}';
  }

  const meses = <String>[
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  if (d.year == now.year) {
    return '${d.day} de ${meses[d.month - 1]}';
  }
  return '${d.day} de ${meses[d.month - 1]} ${d.year}';
}

Map<String, Object?>? _mapaDatosEntrada(Object? raw) {
  if (raw is! Map) return null;
  return Map<String, Object?>.from(
    raw.map((k, v) => MapEntry('$k', v)),
  );
}

class HistorialConsultasPage extends StatelessWidget {
  const HistorialConsultasPage({super.key, this.onHacerConsulta});

  /// Navega a la pestaña Consulta (índice 1 en [MainShell]).
  final VoidCallback? onHacerConsulta;

  @override
  Widget build(BuildContext context) {
    final repo = RegistroConsultaFirestore();

    return StreamBuilder<List<Map<String, Object?>>>(
      stream: repo.historial(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ColoredBox(
            color: _kPageBg,
            child: Center(
              child: CircularProgressIndicator(color: _kAccentBlue),
            ),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return _HistorialVacio(onHacerConsulta: onHacerConsulta);
        }
        return ColoredBox(
          color: _kPageBg,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: items.length,
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _RegistroCard(
                  registro: items[i],
                  onTap: () => _mostrarDesgloseConsulta(context, items[i]),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

void _mostrarDesgloseConsulta(
  BuildContext context,
  Map<String, Object?> registro,
) {
  final datos = _mapaDatosEntrada(registro['datosEntrada']);
  final nivel = '${registro['nivelObesidad'] ?? ''}';
  final dieta = '${registro['dietaRecomendada'] ?? ''}';

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.58,
        minChildSize: 0.38,
        maxChildSize: 0.94,
        expand: false,
        builder: (context, scrollController) {
          return DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 24,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Icon(Icons.fact_check_outlined, color: _kAccentBlue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Datos de la consulta',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1C1C1E),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (nivel.isNotEmpty || dieta.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (nivel.isNotEmpty)
                          Text(
                            'Resultado: ${_nivelLegible(nivel)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF3A3A3C),
                                ),
                          ),
                        if (dieta.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Dieta: $dieta',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF3A3A3C),
                                ),
                          ),
                        ],
                        const Divider(height: 24),
                      ],
                    ),
                  ),
                Expanded(
                  child: datos == null || datos.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'No hay datos de entrada guardados para este registro.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF6B6B6F),
                                  ),
                            ),
                          ),
                        )
                      : Builder(
                          builder: (context) {
                            final keys = _ordenCamposDetalle
                                .where((k) => datos.containsKey(k))
                                .toList();
                            if (keys.isEmpty) {
                              return Center(
                                child: Text(
                                  'No hay campos reconocidos en los datos guardados.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: const Color(0xFF6B6B6F)),
                                ),
                              );
                            }
                            return ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                              itemCount: keys.length,
                              itemBuilder: (context, index) {
                                final key = keys[index];
                                final label = _etiquetasCampo[key] ?? key;
                                final val = _valorLegible(datos[key]);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.label_outline,
                                        size: 18,
                                        color: _kBlueLight,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: const Color(0xFF3A3A3C),
                                                  height: 1.35,
                                                ),
                                            children: [
                                              TextSpan(
                                                text: '$label\n',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1C1C1E),
                                                ),
                                              ),
                                              TextSpan(text: val),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
                SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
              ],
            ),
          );
        },
      );
    },
  );
}

class _HistorialVacio extends StatelessWidget {
  const _HistorialVacio({this.onHacerConsulta});

  final VoidCallback? onHacerConsulta;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ColoredBox(
      color: _kPageBg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: _kPastelBlueBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kAccentBlue.withValues(alpha: 0.14),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.history_toggle_off_rounded,
                  size: 72,
                  color: _kAccentBlue,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'No hay historial para mostrar',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: const Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onHacerConsulta,
                icon: const Icon(Icons.edit_note_outlined, size: 22),
                label: const Text(
                  'Hacer una consulta',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _kAccentBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _kBlueLight.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegistroCard extends StatefulWidget {
  const _RegistroCard({
    required this.registro,
    required this.onTap,
  });

  final Map<String, Object?> registro;
  final VoidCallback onTap;

  @override
  State<_RegistroCard> createState() => _RegistroCardState();
}

class _RegistroCardState extends State<_RegistroCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final r = widget.registro;
    final nivel = '${r['nivelObesidad'] ?? ''}';
    final dieta = '${r['dietaRecomendada'] ?? ''}';
    final fechaTxt = _formatoFechaHumana(r['creadoEn']);
    final conf = r['confianzaPrediccion'];
    final confVal = conf is num ? conf.toDouble().clamp(0.0, 1.0) : null;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: const Border(
          left: BorderSide(color: _kAccentBlue, width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_kCardRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(_kCardRadius),
          splashColor: _kPastelBlueBg.withValues(alpha: 0.9),
          highlightColor: Colors.transparent,
          onTap: widget.onTap,
          onTapDown: (_) {
            if (mounted) setState(() => _pressed = true);
          },
          onTapUp: (_) {
            if (mounted) setState(() => _pressed = false);
          },
          onTapCancel: () {
            if (mounted) setState(() => _pressed = false);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 18, color: _kBlueLight),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        fechaTxt,
                        style: textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF6B6B6F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: _kPastelBlueBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Consulta registrada',
                    style: textTheme.labelMedium?.copyWith(
                      color: _kAccentBlue,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _LineaDato(
                  icon: Icons.analytics_outlined,
                  titulo: 'Nivel (estimado)',
                  valor: _nivelLegible(nivel),
                ),
                const SizedBox(height: 10),
                _LineaDato(
                  icon: Icons.restaurant_menu_outlined,
                  titulo: 'Dieta recomendada',
                  valor: dieta.isEmpty ? '—' : dieta,
                ),
                const SizedBox(height: 14),
                Text(
                  'Seguridad del modelo',
                  style: textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF6B6B6F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                if (confVal != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: confVal,
                      minHeight: 7,
                      backgroundColor: _kPastelBlueBg,
                      color: _kAccentBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(confVal * 100).toStringAsFixed(1)} %',
                    style: textTheme.labelSmall?.copyWith(
                      color: _kAccentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else
                  Text(
                    'Sin dato de confianza',
                    style: textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Toca para ver el desglose',
                    style: textTheme.labelSmall?.copyWith(
                      color: _kBlueLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: card,
    );
  }
}

class _LineaDato extends StatelessWidget {
  const _LineaDato({
    required this.icon,
    required this.titulo,
    required this.valor,
  });

  final IconData icon;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: _kAccentBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF6B6B6F),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF1C1C1E),
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
