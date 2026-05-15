import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../domain/dieta_presentacion_catalogo.dart';

/// Misma línea que la tarjeta «Dietas» del dashboard.
const _kPastelOrangeBg = Color(0xFFFFF3E0);
const _kAccentOrange = Color(0xFFE65100);
const _kOrangeMid = Color(0xFFFF9800);
const _kOrangeLight = Color(0xFFFFCC80);
const _kPageWhite = Color(0xFFFFFFFF);
const _kCardRadius = 20.0;

const _kNaranjasGrafico = <Color>[
  _kAccentOrange,
  _kOrangeMid,
  _kOrangeLight,
];

class DietasInfoPage extends StatelessWidget {
  const DietasInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final items = DietaPresentacionCatalogo.todasEnOrdenUi().toList();

    return ColoredBox(
      color: _kPageWhite,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kPastelOrangeBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: _kAccentOrange,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guía de dietas',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Planes amigables según tu perfil. Toca una tarjeta para ver el detalle.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B6B6F),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          for (final d in items) ...[
            _DietaTarjetaLista(
              presentacion: d,
              onTap: () => _abrirDetalleDieta(context, d),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

void _abrirDetalleDieta(BuildContext context, DietaPresentacion d) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: _kPastelOrangeBg.withValues(alpha: 0.97),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border.all(color: _kOrangeLight.withValues(alpha: 0.6)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 20,
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
                    color: _kAccentOrange.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      24 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: [
                      Text(
                        d.titulo,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1C1C1E),
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        d.objetivo,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF3A3A3C),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Distribución sugerida',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _kAccentOrange,
                            ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: _GraficoMacrosNaranja(macros: d.macros),
                      ),
                      const SizedBox(height: 8),
                      _LeyendaMacros(macros: d.macros),
                      const SizedBox(height: 24),
                      _SeccionDetalle(
                        icono: Icons.eco_outlined,
                        titulo: 'Alimentos',
                        lineas: d.alimentos,
                        colorIcono: _kAccentOrange,
                      ),
                      const SizedBox(height: 20),
                      _SeccionDetalle(
                        icono: Icons.bolt_outlined,
                        titulo: 'Hábitos',
                        lineas: d.habitos,
                        colorIcono: _kOrangeMid,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _GraficoMacrosNaranja extends StatelessWidget {
  const _GraficoMacrosNaranja({required this.macros});

  final List<MacroSlicePresentacion> macros;

  @override
  Widget build(BuildContext context) {
    if (macros.isEmpty) {
      return const Center(child: Text('Sin datos de gráfico'));
    }
    final total = macros.fold<double>(0, (s, m) => s + m.porcentaje);
    if (total <= 0) {
      return const Center(child: Text('Sin datos de gráfico'));
    }

    return PieChart(
      PieChartData(
        centerSpaceColor: Colors.white,
        sectionsSpace: 2,
        centerSpaceRadius: 48,
        sections: [
          for (var i = 0; i < macros.length; i++)
            PieChartSectionData(
              color: _kNaranjasGrafico[i % _kNaranjasGrafico.length],
              value: macros[i].porcentaje,
              title: '${macros[i].porcentaje.toStringAsFixed(0)}%',
              radius: 52,
              titleStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black38, blurRadius: 2)],
              ),
            ),
        ],
      ),
    );
  }
}

class _LeyendaMacros extends StatelessWidget {
  const _LeyendaMacros({required this.macros});

  final List<MacroSlicePresentacion> macros;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < macros.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _kNaranjasGrafico[i % _kNaranjasGrafico.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${macros[i].etiqueta} · ${macros[i].porcentaje.toStringAsFixed(0)} %',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF3A3A3C),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SeccionDetalle extends StatelessWidget {
  const _SeccionDetalle({
    required this.icono,
    required this.titulo,
    required this.lineas,
    required this.colorIcono,
  });

  final IconData icono;
  final String titulo;
  final List<String> lineas;
  final Color colorIcono;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 22, color: colorIcono),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...lineas.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '· ',
                  style: textTheme.bodyMedium?.copyWith(
                    color: _kAccentOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    t,
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF3A3A3C),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DietaTarjetaLista extends StatefulWidget {
  const _DietaTarjetaLista({
    required this.presentacion,
    required this.onTap,
  });

  final DietaPresentacion presentacion;
  final VoidCallback onTap;

  @override
  State<_DietaTarjetaLista> createState() => _DietaTarjetaListaState();
}

class _DietaTarjetaListaState extends State<_DietaTarjetaLista> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final d = widget.presentacion;
    final preview = d.objetivo.length > 120
        ? '${d.objetivo.substring(0, 117)}…'
        : d.objetivo;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: _kPageWhite,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: const Border(
          left: BorderSide(color: _kAccentOrange, width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
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
          splashColor: _kPastelOrangeBg,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kPastelOrangeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.spa_outlined,
                        color: _kAccentOrange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.titulo,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1C1C1E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            preview,
                            style: textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6B6B6F),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Ver detalle',
                    style: textTheme.labelMedium?.copyWith(
                      color: _kAccentOrange,
                      fontWeight: FontWeight.w600,
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
