import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../content/politicas_seguridad.dart';
import '../content/terminos_condiciones.dart';
import '../services/auth_service.dart';
import '../services/perfil_reporte_pdf.dart';
import '../services/registro_consulta_firestore.dart';
import '../theme/dietwise_theme.dart';
import 'auth/login_page.dart';

/// Acento morado pastel — misma familia que la tarjeta «Perfil» del dashboard.
const _kPurpleAccent = Color(0xFF7B1FA2);
const _kPurpleVeryLight = Color(0xFFF3E5F5);
const _kCardRadius = 20.0;

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _auth = AuthService();
  final _consultas = RegistroConsultaFirestore();
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();

  StreamSubscription? _perfilSub;

  var _cargando = true;
  var _guardandoPerfil = false;
  var _generandoPdf = false;
  var _recordatorios = false;
  var _subiendoFoto = false;

  String? _fotoUrlFirestore;
  String? _fotoBase64Firestore;

  Map<String, Object?>? _ultimaConsulta;
  var _numConsultas = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    final user = _auth.usuarioActual;
    if (user != null) {
      _perfilSub = _auth.streamPerfilUsuario(user.uid).listen((snap) {
        if (!mounted) return;
        final data = snap.data();
        setState(() {
          _fotoUrlFirestore = data?['fotoUrl'] as String?;
        });
      });
    }
  }

  @override
  void dispose() {
    _perfilSub?.cancel();
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _edadCtrl.dispose();
    _alturaCtrl.dispose();
    _pesoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final user = _auth.usuarioActual;
    if (user == null) {
      if (mounted) setState(() => _cargando = false);
      return;
    }

    setState(() => _cargando = true);

    try {
      final perfil = await _auth.obtenerPerfilUsuario(user.uid);
      final ultima = await _consultas.ultimaConsultaParaUsuario(user.uid);
      final n = await _consultas.contarConsultasUsuario(user.uid);

      var nombre = (perfil?['nombre'] as String?)?.trim() ?? '';
      var apellido = (perfil?['apellido'] as String?)?.trim() ?? '';

      if (apellido.isEmpty && nombre.contains(' ')) {
        final parts = nombre.split(RegExp(r'\s+'));
        nombre = parts.first;
        apellido = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
      if (nombre.isEmpty) {
        final dn = user.displayName?.trim();
        if (dn != null && dn.isNotEmpty) {
          final parts = dn.split(RegExp(r'\s+'));
          nombre = parts.first;
          apellido = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        }
      }

      _nombreCtrl.text = nombre;
      _apellidoCtrl.text = apellido;

      final edad = perfil?['edad'];
      _edadCtrl.text = edad == null ? '' : '$edad';

      final alt = _doubleDe(perfil?['altura']);
      final pes = _doubleDe(perfil?['peso']);
      _alturaCtrl.text = alt == null ? '' : _formatDecimal(alt);
      _pesoCtrl.text = pes == null ? '' : _formatDecimal(pes);

      final rec = perfil?['recordatorios'];
      _recordatorios = rec is bool ? rec : false;

      final b64 = perfil?['fotoBase64'] as String?;
      _fotoBase64Firestore = b64;
      _fotoUrlFirestore = perfil?['fotoUrl'] as String?;

      _ultimaConsulta = ultima;
      _numConsultas = n;
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  static String _formatDecimal(double v) {
    if (v == v.roundToDouble()) return '${v.toInt()}';
    return v.toStringAsFixed(v >= 10 ? 1 : 2);
  }

  static double? _doubleDe(Object? v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  static Map<String, Object?>? _mapaDatosEntrada(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw.map((k, v) => MapEntry(k, v));
    }
    if (raw is Map) {
      return raw.map((k, v) => MapEntry('$k', v));
    }
    return null;
  }

  String _nivelIndiceLegible() {
    final raw = _ultimaConsulta?['nivelObesidad'];
    if (raw == null) return '—';
    return '$raw'.replaceAll('_', ' ');
  }

  double? _imcDesdePerfilOConsulta() {
    final h = _doubleDe(_alturaCtrl.text.replaceAll(',', '.'));
    final w = _doubleDe(_pesoCtrl.text.replaceAll(',', '.'));
    if (h != null && h > 0 && w != null && w > 0) {
      return w / (h * h);
    }
    final datos = _mapaDatosEntrada(_ultimaConsulta?['datosEntrada']);
    if (datos == null) return null;
    final h2 = _doubleDe(datos['Altura']);
    final w2 = _doubleDe(datos['Peso']);
    if (h2 != null && h2 > 0 && w2 != null && w2 > 0) {
      return w2 / (h2 * h2);
    }
    return null;
  }

  String _textoConsultas() {
    final n = _numConsultas;
    if (n == 0) return '0 realizados';
    if (n == 1) return '1 realizado';
    return '$n realizados';
  }

  Future<Uint8List?> _bytesFotoParaPdf() async {
    final url = _fotoUrlFirestore;
    if (url != null && url.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) return res.bodyBytes;
      } catch (_) {}
    }
    return PerfilReportePdf.bytesDesdeBase64(_fotoBase64Firestore);
  }

  Widget _avatarPlaceholder(TextTheme textTheme) {
    return ColoredBox(
      color: DietWiseColors.pastelBorder.withValues(alpha: 0.35),
      child: Center(
        child: Text(
          _iniciales(),
          style: textTheme.headlineMedium?.copyWith(
            color: _kPurpleAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(TextTheme textTheme) {
    if (_subiendoFoto) {
      return ColoredBox(
        color: _kPurpleVeryLight.withValues(alpha: 0.65),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _kPurpleAccent,
            ),
          ),
        ),
      );
    }
    final url = _fotoUrlFirestore;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          final total = progress.expectedTotalBytes;
          final value = total != null
              ? progress.cumulativeBytesLoaded / total
              : null;
          return ColoredBox(
            color: DietWiseColors.pastelBorder.withValues(alpha: 0.25),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _kPurpleAccent,
                  value: value,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            _avatarPlaceholder(textTheme),
      );
    }
    final legacy = PerfilReportePdf.bytesDesdeBase64(_fotoBase64Firestore);
    if (legacy != null && legacy.isNotEmpty) {
      return Image.memory(legacy, fit: BoxFit.cover);
    }
    return _avatarPlaceholder(textTheme);
  }

  String _iniciales() {
    final a = _nombreCtrl.text.trim();
    final b = _apellidoCtrl.text.trim();
    final s = '${a.isNotEmpty ? a[0] : ''}${b.isNotEmpty ? b[0] : ''}';
    if (s.isEmpty) return 'U';
    return s.toUpperCase();
  }

  String _nombreCompletoVisual() {
    final a = _nombreCtrl.text.trim();
    final b = _apellidoCtrl.text.trim();
    if (a.isEmpty && b.isEmpty) return 'Usuario';
    return '$a $b'.trim();
  }

  void _mostrarSheetFotoPerfil() {
    final textTheme = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_kCardRadius),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DietWiseColors.pastelBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Foto de perfil',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: DietWiseColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'La imagen se guardará en la nube de forma segura.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: DietWiseColors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: _kPurpleAccent.withValues(alpha: 0.25),
                    ),
                  ),
                  leading: Icon(
                    Icons.photo_library_outlined,
                    color: _kPurpleAccent,
                  ),
                  title: const Text('Elegir de la galería'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadFromGallery();
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(
                      Icons.arrow_back,
                      color: DietWiseColors.textSecondary,
                    ),
                    label: Text(
                      'Cancelar',
                      style: TextStyle(color: DietWiseColors.textSecondary),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: _kPurpleAccent.withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_kCardRadius),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadFromGallery() async {
    final user = _auth.usuarioActual;
    if (user == null || !mounted) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 88,
    );
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    setState(() => _subiendoFoto = true);

    try {
      await _auth.subirFotoPerfilStorage(uid: user.uid, bytes: bytes);
      if (!mounted) return;
      setState(() => _fotoBase64Firestore = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil actualizada.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_auth.mensajeParaError(e))),
      );
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _auth.usuarioActual;
    if (user == null) return;

    setState(() => _guardandoPerfil = true);
    try {
      final edad = int.tryParse(_edadCtrl.text.trim());
      final altura = _doubleDe(_alturaCtrl.text.replaceAll(',', '.'));
      final peso = _doubleDe(_pesoCtrl.text.replaceAll(',', '.'));

      await _auth.actualizarPerfilUsuario(
        uid: user.uid,
        nombre: _nombreCtrl.text,
        apellido: _apellidoCtrl.text,
        edad: edad,
        altura: altura,
        peso: peso,
        recordatorios: _recordatorios,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados correctamente.')),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_auth.mensajeErrorFirestore(e))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_auth.mensajeParaError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _guardandoPerfil = false);
    }
  }

  Future<void> _exportarPdf() async {
    final user = _auth.usuarioActual;
    if (user == null) return;

    setState(() => _generandoPdf = true);
    try {
      final edad = int.tryParse(_edadCtrl.text.trim());
      final altura = _doubleDe(_alturaCtrl.text.replaceAll(',', '.'));
      final peso = _doubleDe(_pesoCtrl.text.replaceAll(',', '.'));

      final fotoBytes = await _bytesFotoParaPdf();

      final resultado = await PerfilReportePdf.generarYPrevisualizar(
        fotoPerfilBytes: fotoBytes,
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        email: user.email ?? '',
        edad: edad,
        altura: altura,
        peso: peso,
        ultimaConsulta: _ultimaConsulta,
        numConsultas: _numConsultas,
        imc: _imcDesdePerfilOConsulta(),
      );

      if (!mounted) return;

      switch (resultado) {
        case PerfilReportePdfResultado.guardado:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Reporte guardado con éxito en el dispositivo!'),
            ),
          );
        case PerfilReportePdfResultado.cancelado:
          break;
        case PerfilReportePdfResultado.error:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo guardar el PDF. Intente de nuevo o compruebe el espacio disponible.',
              ),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _generandoPdf = false);
    }
  }

  Future<void> _aplicarRecordatorios(bool v) async {
    final user = _auth.usuarioActual;
    if (user == null) return;

    final prev = _recordatorios;
    setState(() => _recordatorios = v);

    try {
      await _auth.actualizarPerfilUsuario(
        uid: user.uid,
        nombre: _nombreCtrl.text.trim().isEmpty ? 'Usuario' : _nombreCtrl.text,
        apellido: _apellidoCtrl.text,
        edad: int.tryParse(_edadCtrl.text.trim()),
        altura: _doubleDe(_alturaCtrl.text.replaceAll(',', '.')),
        peso: _doubleDe(_pesoCtrl.text.replaceAll(',', '.')),
        recordatorios: v,
      );
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() => _recordatorios = prev);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_auth.mensajeErrorFirestore(e))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _recordatorios = prev);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_auth.mensajeParaError(e))),
        );
      }
    }
  }

  Future<void> _cerrarSesion() async {
    await _auth.cerrarSesion();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _dialogoAcerca() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kCardRadius)),
        title: const Text('Acerca de DietWise'),
        content: const Text(
          'DietWise es una herramienta de salud diseñada para combatir la '
          'obesidad, proporcionando dietas personalizadas y seguimiento '
          'metabólico preciso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _modalLegal(String titulo, String texto) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kCardRadius)),
        title: Text(titulo),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              texto,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  static RoundedRectangleBorder get _cardShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kCardRadius),
        side: const BorderSide(color: DietWiseColors.pastelBorder),
      );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final email = _auth.usuarioActual?.email ?? '';

    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: 132,
                  height: 132,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 124,
                        height: 124,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _kPurpleAccent, width: 4),
                        ),
                        child: ClipOval(
                          child: _buildAvatarContent(textTheme),
                        ),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Material(
                          color: _kPurpleAccent,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _subiendoFoto ? null : _mostrarSheetFotoPerfil,
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(
                                Icons.photo_camera_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _nombreCompletoVisual(),
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: DietWiseColors.textPrimary,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF424242),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _MiniStatCard(
                      titulo: 'Índice',
                      subtitulo: 'IMC / obesidad',
                      valor: _nivelIndiceLegible(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStatCard(
                      titulo: 'Consultas',
                      subtitulo: 'Historial',
                      valor: _textoConsultas(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                clipBehavior: Clip.antiAlias,
                elevation: 0,
                shape: _cardShape,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Datos biométricos',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: DietWiseColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nombreCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: _campoMorado(
                            label: 'Nombre',
                            icon: Icons.badge_outlined,
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Requerido' : null,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _apellidoCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: _campoMorado(
                            label: 'Apellido',
                            icon: Icons.person_outline,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _edadCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _campoMorado(
                            label: 'Edad',
                            icon: Icons.cake_outlined,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _alturaCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _campoMorado(
                            label: 'Altura (m)',
                            icon: Icons.height,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pesoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _campoMorado(
                            label: 'Peso (kg)',
                            icon: Icons.monitor_weight_outlined,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _guardandoPerfil ? null : _guardarPerfil,
                            style: FilledButton.styleFrom(
                              backgroundColor: _kPurpleAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _guardandoPerfil
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Guardar Cambios'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                elevation: 0,
                shape: _cardShape,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.info_outline, color: _kPurpleAccent.withValues(alpha: 0.9)),
                      title: const Text('Acerca de la app'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _dialogoAcerca,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.description_outlined, color: _kPurpleAccent.withValues(alpha: 0.9)),
                      title: const Text('Exportar reporte nutricional (PDF)'),
                      subtitle: const Text('Vista previa e impresión'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _generandoPdf ? null : _exportarPdf,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Card(
                elevation: 0,
                shape: _cardShape,
                child: SwitchListTile(
                  activeThumbColor: _kPurpleAccent,
                  activeTrackColor: _kPurpleAccent.withValues(alpha: 0.35),
                  inactiveThumbColor: DietWiseColors.textMuted,
                  inactiveTrackColor: DietWiseColors.pastelBorder,
                  secondary: Icon(Icons.notifications_outlined, color: _kPurpleAccent.withValues(alpha: 0.85)),
                  title: const Text('Notificaciones'),
                  subtitle: const Text('Recordatorios de hábitos y consulta'),
                  value: _recordatorios,
                  onChanged: (v) => _aplicarRecordatorios(v),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton(
                    onPressed: () => _modalLegal(
                      'Políticas de seguridad',
                      dietWisePoliticasSeguridad,
                    ),
                    child: Text(
                      'Políticas de seguridad',
                      style: TextStyle(
                        color: DietWiseColors.textSecondary.withValues(alpha: 0.85),
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: DietWiseColors.textMuted,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _modalLegal(
                      'Términos y condiciones',
                      dietWiseTerminosYCondiciones,
                    ),
                    child: Text(
                      'Términos y condiciones',
                      style: TextStyle(
                        color: DietWiseColors.textSecondary.withValues(alpha: 0.85),
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: DietWiseColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _cerrarSesion,
                icon: const Icon(Icons.logout, color: Color(0xFFC62828)),
                label: const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: Color(0xFFC62828),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_generandoPdf)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black26,
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_kCardRadius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Generando PDF…',
                          style: textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  InputDecoration _campoMorado({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _kPurpleAccent),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.titulo,
    required this.subtitulo,
    required this.valor,
  });

  final String titulo;
  final String subtitulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: _kPurpleVeryLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kCardRadius),
        side: BorderSide(color: _kPurpleAccent.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: textTheme.labelMedium?.copyWith(
                color: _kPurpleAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitulo,
              style: textTheme.bodySmall?.copyWith(
                color: DietWiseColors.textMuted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              valor,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: DietWiseColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
