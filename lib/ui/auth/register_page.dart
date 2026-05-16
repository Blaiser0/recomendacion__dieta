import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/dietwise_theme.dart';
import '../main_shell.dart';
import 'auth_error_ui.dart';
import 'dietwise_auth_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmar = TextEditingController();
  final _auth = AuthService();

  var _cargando = false;
  var _aceptaTerminos = false;
  var _ocultarPassword = true;
  var _ocultarConfirmar = true;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _crearCuenta() async {
    if (!_aceptaTerminos) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    try {
      await _auth.registrar(
        nombre: _nombre.text,
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

  @override
  Widget build(BuildContext context) {
    final puedeCrear = _aceptaTerminos && !_cargando;

    return Scaffold(
      backgroundColor: DietWiseColors.pastelBg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Registro'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: DietWiseAuthBody(
          extraPadding: const EdgeInsets.only(top: 4),
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
                        controller: _nombre,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: DietWiseColors.textMuted,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ingrese su nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
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
                        textInputAction: TextInputAction.next,
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
                          if (v == null || v.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmar,
                        obscureText: _ocultarConfirmar,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (puedeCrear) _crearCuenta();
                        },
                        decoration: InputDecoration(
                          labelText: 'Confirmar contraseña',
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: DietWiseColors.textMuted,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultarConfirmar
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: DietWiseColors.textMuted,
                            ),
                            onPressed: () => setState(
                              () => _ocultarConfirmar = !_ocultarConfirmar,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v != _password.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _aceptaTerminos,
                            onChanged: _cargando
                                ? null
                                : (v) => setState(
                                      () => _aceptaTerminos = v ?? false,
                                    ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    color: DietWiseColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Acepto los '),
                                    TextSpan(
                                      text: 'Términos y Condiciones',
                                      style: const TextStyle(
                                        color: DietWiseColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () =>
                                            mostrarTerminosDialog(context),
                                    ),
                                    const TextSpan(
                                      text:
                                          ' y la política de privacidad.',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DietWisePrimaryButton(
                        label: 'Crear cuenta',
                        loading: _cargando,
                        onPressed: puedeCrear ? _crearCuenta : null,
                      ),
                    ],
                  ),
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
