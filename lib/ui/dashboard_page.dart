import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/dashboard_stats.dart';
import '../services/auth_service.dart';
import '../services/registro_consulta_firestore.dart';
import '../theme/dietwise_theme.dart';

/// Colores: verdes/azules (normal / bajo peso) y naranja/rojo (sobrepeso/obesidad).
Color _colorNivel(String nivel) {
  switch (nivel) {
    case 'Peso_normal':
      return const Color(0xFF2E7D32);
    case 'Peso_insuficiente':
      return const Color(0xFF1E88E5);
    case 'Sobrepeso_Nivel_I':
      return const Color(0xFFFFB300);
    case 'Sobrepeso_Nivel_II':
      return const Color(0xFFFF6D00);
    case 'Obesidad_Tipo_I':
      return const Color(0xFFE65100);
    case 'Obesidad_Tipo_II':
      return const Color(0xFFC62828);
    case 'Obesidad_Tipo_III':
      return const Color(0xFF8B1538);
    default:
      return Colors.grey;
  }
}

String _etiquetaCorta(String nivel) {
  switch (nivel) {
    case 'Obesidad_Tipo_I':
      return 'Obes. I';
    case 'Obesidad_Tipo_II':
      return 'Obes. II';
    case 'Obesidad_Tipo_III':
      return 'Obes. III';
    case 'Peso_insuficiente':
      return 'Bajo peso';
    case 'Peso_normal':
      return 'Normal';
    case 'Sobrepeso_Nivel_I':
      return 'Sobrep. I';
    case 'Sobrepeso_Nivel_II':
      return 'Sobrep. II';
    default:
      return nivel;
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, this.onIrASeccion});

  /// Índices del [MainShell]: 1=Consulta, 2=Historial, 3=Dietas, 4=Perfil.
  final ValueChanged<int>? onIrASeccion;

  @override
  Widget build(BuildContext context) {
    final repo = RegistroConsultaFirestore();
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<DashboardStats>(
      stream: repo.watchDashboardStats(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorDashboard(error: snapshot.error);
        }
        final stats = snapshot.data;
        if (stats == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFE3F2FD),
                      child: Text(
                        'R',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1565C0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, Renzo',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1C1C1E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bienvenido de nuevo',
                            style: textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6B6B6F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.35,
                ),
                delegate: SliverChildListDelegate([
                  _StatCard(
                    title: 'Consulta',
                    value: stats.consultasUltimos7Dias,
                    icon: Icons.edit_note,
                    iconBackground: const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF2E7D32),
                    consultaSplash: true,
                    onTap: () => onIrASeccion?.call(1),
                  ),
                  _StatCard(
                    title: 'Historial',
                    value: stats.totalRegistros,
                    icon: Icons.history,
                    iconBackground: const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF1565C0),
                    onTap: () => onIrASeccion?.call(2),
                  ),
                  _StatCard(
                    title: 'Dietas',
                    value: stats.dietasDistintas,
                    icon: Icons.apple,
                    iconBackground: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFE65100),
                    onTap: () => onIrASeccion?.call(3),
                  ),
                  _StatCard(
                    title: 'Perfil',
                    value: 1,
                    icon: Icons.person,
                    iconBackground: const Color(0xFFF3E5F5),
                    iconColor: const Color(0xFF7B1FA2),
                    onTap: () => onIrASeccion?.call(4),
                  ),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: _DonutCard(stats: stats),
              ),
            ),
          ],
        );
      },
    );
  }
}

const double _kStatCardRadius = 20;

/// Splash verde pastel muy suave (tarjeta Consulta).
const Color _kSplashConsulta = Color(0x2681C784);

class _StatCard extends StatefulWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    this.consultaSplash = false,
    this.onTap,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final bool consultaSplash;
  final VoidCallback? onTap;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _pressed = false;

  static const _radius = BorderRadius.all(Radius.circular(_kStatCardRadius));

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final content = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C1C1E),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${widget.value}',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C1C1E),
            ),
          ),
        ],
      ),
    );

    final cardShape = RoundedRectangleBorder(borderRadius: _radius);

    final card = Card(
      clipBehavior: Clip.antiAlias,
      shape: cardShape,
      elevation: Theme.of(context).cardTheme.elevation ?? 1,
      child: widget.onTap == null
          ? content
          : InkWell(
              borderRadius: _radius,
              splashColor:
                  widget.consultaSplash ? _kSplashConsulta : Colors.black12,
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
              child: content,
            ),
    );

    if (widget.onTap == null) return card;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: card,
    );
  }
}

class _DonutCard extends StatelessWidget {
  const _DonutCard({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = DashboardStats.ordenNiveles.fold<int>(
      0,
      (s, k) => s + (stats.porNivel[k] ?? 0),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Las dietas recomendadas:',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Distribución por nivel de obesidad (IA) — registros_consulta',
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B6B6F),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: total == 0
                  ? Center(
                      child: Text(
                        'Sin consultas aún.\nRealice una consulta para ver el gráfico.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6B6B6F),
                        ),
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF90CAF9,
                                ).withValues(alpha: 0.25),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 52,
                              sections: _secciones(stats, total),
                              pieTouchData: PieTouchData(enabled: true),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$total',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'consultas',
                              style: textTheme.labelMedium?.copyWith(
                                color: const Color(0xFF6B6B6F),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            _Leyenda(stats: stats, total: total),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _secciones(DashboardStats stats, int total) {
    final secciones = <PieChartSectionData>[];
    for (final nivel in DashboardStats.ordenNiveles) {
      final c = stats.porNivel[nivel] ?? 0;
      if (c == 0) continue;
      final pct = (100.0 * c) / total;
      secciones.add(
        PieChartSectionData(
          color: _colorNivel(nivel),
          value: c.toDouble(),
          title: '${pct.toStringAsFixed(0)}%',
          radius: 38,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
          ),
        ),
      );
    }
    return secciones;
  }
}

class _ErrorDashboard extends StatelessWidget {
  const _ErrorDashboard({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final text = error.toString();
    final esPermiso = text.contains('permission-denied');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
              color: esPermiso ? DietWiseColors.textMuted : Colors.red.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              esPermiso
                  ? 'Sin permiso para leer Firestore'
                  : 'No se pudo cargar el inicio',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              esPermiso
                  ? 'Inicie sesión y publique las reglas de Firestore del proyecto '
                      '${AuthService.firebaseProjectId}.\n\n'
                      'Firestore → Reglas → copiar firestore.rules del proyecto → Publicar.\n\n'
                      'Debe permitir lectura de registros_consulta a usuarios autenticados.'
                  : text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B6B6F),
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.stats, required this.total});

  final DashboardStats stats;
  final int total;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: DashboardStats.ordenNiveles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 12,
        childAspectRatio: 4.2,
      ),
      itemBuilder: (context, i) {
        final nivel = DashboardStats.ordenNiveles[i];
        return Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _colorNivel(nivel),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                total == 0
                    ? '${_etiquetaCorta(nivel)} — 0 %'
                    : '${_etiquetaCorta(nivel)} — ${((100 * (stats.porNivel[nivel] ?? 0)) / total).toStringAsFixed(1)} %',
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF3A3A3C),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
