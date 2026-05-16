import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/dietwise_theme.dart';

/// Muestra errores de registro/login en español, con guía según la causa real.
void mostrarErrorAuth(BuildContext context, Object error, AuthService auth) {
  final mensaje = auth.mensajeParaError(error);
  final debugExtra = auth.detalleTecnicoDebug(error);

  final esEmailOff = error is FirebaseAuthException &&
      auth.esEmailPasswordNoHabilitado(error);
  final esFirestore = error is FirebaseException &&
      auth.esFirestorePermisoDenegado(error);
  final esConfigAuth = error is FirebaseAuthException &&
      auth.esErrorConfiguracionAuth(error);

  if (esEmailOff || esFirestore || esConfigAuth) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DietWiseColors.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DietWiseColors.cardRadius),
        ),
        title: Text(
          esFirestore
              ? 'Perfil no guardado'
              : 'No se pudo completar el registro',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: DietWiseColors.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mensaje,
                style: const TextStyle(
                  color: DietWiseColors.textSecondary,
                  height: 1.45,
                  fontSize: 14,
                ),
              ),
              if (esEmailOff) ...[
                const SizedBox(height: 12),
                SelectableText(
                  AuthService.urlConsolaAuthEmail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: DietWiseColors.textPrimary,
                  ),
                ),
              ],
              if (debugExtra != null) ...[
                const SizedBox(height: 12),
                Text(
                  debugExtra,
                  style: const TextStyle(
                    fontSize: 11,
                    color: DietWiseColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
    return;
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          debugExtra != null ? '$mensaje\n($debugExtra)' : mensaje,
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
}
