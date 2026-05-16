import 'package:flutter/material.dart';

import '../../content/terminos_condiciones.dart';
import '../../theme/dietwise_theme.dart';

/// Logo unificado DietWise (`logocompleto.png`), ~45 % del ancho de pantalla.
class DietWiseLogoCompleto extends StatelessWidget {
  const DietWiseLogoCompleto({super.key, this.anchoFraccion});

  /// Por defecto [DietWiseColors.logoAnchoFraccion] (0.45).
  final double? anchoFraccion;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width *
        (anchoFraccion ?? DietWiseColors.logoAnchoFraccion);
    return Image.asset(
      DietWiseColors.logoCompletoAsset,
      width: ancho,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.restaurant_menu_outlined,
        size: ancho * 0.5,
        color: DietWiseColors.textMuted,
      ),
    );
  }
}

/// Espacio dinámico entre logo y formulario (~5 % de la altura de pantalla).
class DietWiseLogoFormularioGap extends StatelessWidget {
  const DietWiseLogoFormularioGap({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: DietWiseColors.logoFormularioGap(context));
  }
}

/// Scroll + [LayoutBuilder]: centrado vertical en pantallas altas; scroll si hay
/// teclado o poco espacio (teléfonos pequeños, tablets en landscape, etc.).
class DietWiseAuthBody extends StatelessWidget {
  const DietWiseAuthBody({
    super.key,
    required this.children,
    this.extraPadding,
  });

  final List<Widget> children;
  final EdgeInsets? extraPadding;

  @override
  Widget build(BuildContext context) {
    final padH = DietWiseColors.authPaddingHorizontal(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minH = constraints.maxHeight;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            left: padH.left + (extraPadding?.left ?? 0),
            right: padH.right + (extraPadding?.right ?? 0),
            top: 12 + (extraPadding?.top ?? 0),
            bottom: 24 + bottomInset + (extraPadding?.bottom ?? 0),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minH),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

class DietWiseAuthCard extends StatelessWidget {
  const DietWiseAuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DietWiseColors.cardWhite,
        borderRadius: BorderRadius.circular(DietWiseColors.cardRadius),
        border: Border.all(color: DietWiseColors.pastelBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class DietWisePrimaryButton extends StatelessWidget {
  const DietWisePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: onPressed == null
            ? DietWiseColors.pastelBorder
            : DietWiseColors.buttonGray,
        borderRadius: BorderRadius.circular(DietWiseColors.inputRadius),
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(DietWiseColors.inputRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class DietWiseOutlineButton extends StatelessWidget {
  const DietWiseOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: DietWiseColors.textPrimary,
          backgroundColor: DietWiseColors.cardWhite,
          side: const BorderSide(color: DietWiseColors.pastelBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DietWiseColors.inputRadius),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}

void mostrarTerminosDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DietWiseColors.cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DietWiseColors.cardRadius),
      ),
      title: const Text(
        'Términos y Condiciones',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: DietWiseColors.textPrimary,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Text(
            dietWiseTerminosYCondiciones,
            style: const TextStyle(
              color: DietWiseColors.textSecondary,
              height: 1.45,
              fontSize: 13,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}
