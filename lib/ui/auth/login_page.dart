import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/dietwise_theme.dart';
import '../main_shell.dart';
import 'auth_error_ui.dart';
import 'dietwise_auth_widgets.dart';
import 'register_page.dart';

const Color _kPurpleAccent = Color(0xFF7B1FA2);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.mensajeExito});

  /// Mensaje breve tras registro exitoso (p. ej. cuenta creada).
  final String? mensajeExito;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  var _cargando = false;
  var _ocultarPassword = true;

  @override
  void initState() {
    super.initState();
    final msg = widget.mensajeExito;
    if (msg != null && msg.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mostrarExito(msg);
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await _auth.iniciarSesion(
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      mostrarErrorAuth(context, e, _auth);
    } catch (e) {
      if (!mounted) return;
      mostrarErrorAuth(context, e, _auth);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _olvidoContrasena() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _mostrarAviso('Ingrese su correo en el campo Email para enviar el enlace.');
      return;
    }
    try {
      await _auth.enviarRestablecimientoContrasena(email);
      if (!mounted) return;
      _mostrarAviso('Se envió un correo de recuperación a $email');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      mostrarErrorAuth(context, e, _auth);
    } catch (e) {
      if (!mounted) return;
      mostrarErrorAuth(context, e, _auth);
    }
  }

  void _mostrarAviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: _kPurpleAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DietWiseColors.pastelBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: DietWiseAuthBody(
          children: [
            Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DietWiseLogoCompleto(),
                  const DietWiseLogoFormularioGap(),
                  DietWiseAuthCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(
                              Icons.mail_outline,
                              color: DietWiseColors.textMuted,
                            ),
                          ),
                          validator: (v) {
                            final t = v?.trim() ?? '';
                            if (t.isEmpty) return 'Ingrese su correo';
                            if (!t.contains('@')) return 'Correo no válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          obscureText: _ocultarPassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _entrar(),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: DietWiseColors.textMuted,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _ocultarPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: DietWiseColors.textMuted,
                              ),
                              onPressed: () => setState(
                                () => _ocultarPassword = !_ocultarPassword,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Ingrese su contraseña';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _cargando ? null : _olvidoContrasena,
                            child: const Text(
                              '¿Olvidó su contraseña?',
                              style: TextStyle(
                                fontSize: 13,
                                color: DietWiseColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DietWisePrimaryButton(
                          label: 'Entrar',
                          loading: _cargando,
                          onPressed: _cargando ? null : _entrar,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  DietWiseOutlineButton(
                    label: 'Crear cuenta',
                    onPressed: () {
                      if (_cargando) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RegisterPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
