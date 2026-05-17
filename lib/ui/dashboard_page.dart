import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../domain/dieta_presentacion_catalogo.dart';
import '../models/dashboard_stats.dart';
import '../services/auth_service.dart';
import '../services/registro_consulta_firestore.dart';
import '../theme/dietwise_theme.dart';

/// Morado pastel del dashboard (tarjeta Perfil).
const _kPurpleAccent = Color(0xFF7B1FA2);
const _kPurpleVeryLight = Color(0xFFF3E5F5);

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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: _DashboardWelcomeHeader(
                  onIrAPerfil: () => onIrASeccion?.call(4),
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
                    value: stats.totalDietasCatalogo,
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
                child: StreamBuilder<DistribucionGlobalGrafico>(
                  stream: repo.watchDistribucionGlobalGrafico(),
                  builder: (context, globalSnap) {
                    if (globalSnap.hasError) {
                      return _DonutCardError(error: globalSnap.error);
                    }
                    final global =
                        globalSnap.data ?? DistribucionGlobalGrafico.vacio();
                    return _DonutCard(distribucion: global);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Cabecera bajo «Inicio»: avatar (fotoUrl) + saludo dinámico desde Firestore.
class _DashboardWelcomeHeader extends StatelessWidget {
  const _DashboardWelcomeHeader({this.onIrAPerfil});

  final VoidCallback? onIrAPerfil;

  static const _avatarRadius = 28.0;

  static String _nombreParaSaludo(Map<String, dynamic>? data, User? user) {
    if (data == null) {
      final dn = user?.displayName?.trim();
      if (dn != null && dn.isNotEmpty) return dn;
      return 'Usuario';
    }
    var nombre = (data['nombre'] as String?)?.trim() ?? '';
    var apellido = (data['apellido'] as String?)?.trim() ?? '';

    if (apellido.isEmpty && nombre.contains(' ')) {
      final parts = nombre.split(RegExp(r'\s+'));
      nombre = parts.first;
      apellido = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }
    if (nombre.isEmpty) {
      final dn = user?.displayName?.trim();
      if (dn != null && dn.isNotEmpty) return dn;
      return 'Usuario';
    }
    if (apellido.isEmpty) return nombre;
    return '$nombre $apellido';
  }

  static String _iniciales(Map<String, dynamic>? data, User? user) {
    if (data != null) {
      final n = (data['nombre'] as String?)?.trim() ?? '';
      final a = (data['apellido'] as String?)?.trim() ?? '';
      if (a.isNotEmpty && n.isNotEmpty) {
        return '${n[0]}${a[0]}'.toUpperCase();
      }
      if (n.isNotEmpty) return n[0].toUpperCase();
    }
    final dn = user?.displayName?.trim();
    if (dn != null && dn.isNotEmpty) {
      final parts = dn.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
      }
      return dn[0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final auth = AuthService();
    final user = auth.usuarioActual;

    if (user == null) {
      return _filaEstatica(
        context,
        saludo: 'Hi, Usuario',
        avatar: _avatarPlaceholder(textTheme, 'U', fotoUrl: null),
      );
    }

    return StreamBuilder(
      stream: auth.streamPerfilUsuario(user.uid),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final fotoUrl = data?['fotoUrl'] as String?;
        final saludo = 'Hi, ${_nombreParaSaludo(data, user)}';

        final avatar = Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onIrAPerfil,
            customBorder: const CircleBorder(),
            child: CircleAvatar(
              radius: _avatarRadius,
              backgroundColor: _kPurpleVeryLight,
              child: _avatarContenido(
                textTheme: textTheme,
                fotoUrl: fotoUrl,
                iniciales: _iniciales(data, user),
                cargando: snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData,
              ),
            ),
          ),
        );

        return _filaEstatica(
          context,
          saludo: saludo,
          avatar: avatar,
        );
      },
    );
  }

  Widget _filaEstatica(
    BuildContext context, {
    required String saludo,
    required Widget avatar,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        avatar,
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                saludo,
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
    );
  }

  Widget _avatarPlaceholder(
    TextTheme textTheme,
    String iniciales, {
    String? fotoUrl,
  }) {
    return CircleAvatar(
      radius: _avatarRadius,
      backgroundColor: _kPurpleVeryLight,
      child: _avatarContenido(
        textTheme: textTheme,
        fotoUrl: fotoUrl,
        iniciales: iniciales,
        cargando: false,
      ),
    );
  }

  Widget _avatarContenido({
    required TextTheme textTheme,
    required String? fotoUrl,
    required String iniciales,
    required bool cargando,
  }) {
    if (cargando) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _kPurpleAccent,
        ),
      );
    }
    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          fotoUrl,
          width: _avatarRadius * 2,
          height: _avatarRadius * 2,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kPurpleAccent,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.person,
            size: 32,
            color: _kPurpleAccent.withValues(alpha: 0.85),
          ),
        ),
      );
    }
    return Text(
      iniciales,
      style: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: _kPurpleAccent,
      ),
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

class _DonutCardError extends StatelessWidget {
  const _DonutCardError({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'No se pudo cargar el gráfico global.\n$error',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B6B6F),
              ),
        ),
      ),
    );
  }
}

class _DonutCard extends StatelessWidget {
  const _DonutCard({required this.distribucion});

  final DistribucionGlobalGrafico distribucion;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final totalCatalogo = distribucion.totalConsultasEnCatalogo;
    final numPlanes = DietaPresentacionCatalogo.cantidadDietas;

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
              'Distribución global de consultas entre los $numPlanes planes '
              'del catálogo (todos los usuarios)',
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B6B6F),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: totalCatalogo == 0
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
                              sections: _secciones(distribucion, totalCatalogo),
                              pieTouchData: PieTouchData(enabled: true),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$totalCatalogo',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'de $numPlanes planes',
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
            _Leyenda(distribucion: distribucion, total: totalCatalogo),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _secciones(
    DistribucionGlobalGrafico distribucion,
    int total,
  ) {
    final secciones = <PieChartSectionData>[];
    for (final nivel in ordenNivelesDietasUi) {
      final c = distribucion.porNivel[nivel] ?? 0;
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
  const _Leyenda({required this.distribucion, required this.total});

  final DistribucionGlobalGrafico distribucion;
  final int total;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ordenNivelesDietasUi.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 12,
        childAspectRatio: 4.2,
      ),
      itemBuilder: (context, i) {
        final nivel = ordenNivelesDietasUi[i];
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
                    : '${_etiquetaCorta(nivel)} — ${((100 * (distribucion.porNivel[nivel] ?? 0)) / total).toStringAsFixed(1)} %',
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
