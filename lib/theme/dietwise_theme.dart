import 'package:flutter/material.dart';

/// Identidad DietWise: blanco y gris pastel (errores en rojo del tema).
abstract final class DietWiseColors {
  static const pastelBg = Color(0xFFF5F5F5);
  static const pastelBorder = Color(0xFFE0E0E0);
  static const cardWhite = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textMuted = Color(0xFF9E9E9E);
  static const buttonGray = Color(0xFF9E9E9E);
  static const buttonGrayDark = Color(0xFF757575);

  static const cardRadius = 25.0;
  static const inputRadius = 16.0;
  static const logoCompletoAsset = 'assets/logo/logocompleto.png';

  /// Ancho del logo respecto al ancho de pantalla (45 %).
  static const logoAnchoFraccion = 0.45;

  /// Separación logo–formulario: fracción de la altura útil de pantalla (5 %).
  static const logoFormularioGapFraccion = 0.05;

  static const logoFormularioGapMin = 28.0;
  static const logoFormularioGapMax = 56.0;

  /// Padding horizontal de pantallas auth (% del ancho, con límites).
  static const authPaddingHorizontalFraccion = 0.06;
  static const authPaddingHorizontalMin = 16.0;
  static const authPaddingHorizontalMax = 40.0;

  static double logoFormularioGap(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return (h * logoFormularioGapFraccion)
        .clamp(logoFormularioGapMin, logoFormularioGapMax);
  }

  static EdgeInsets authPaddingHorizontal(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = (w * authPaddingHorizontalFraccion)
        .clamp(authPaddingHorizontalMin, authPaddingHorizontalMax);
    return EdgeInsets.symmetric(horizontal: h);
  }
}

ThemeData buildDietWiseTheme() {
  const error = Color(0xFFC62828);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: DietWiseColors.pastelBg,
    colorScheme: const ColorScheme.light(
      primary: DietWiseColors.buttonGrayDark,
      onPrimary: Colors.white,
      surface: DietWiseColors.cardWhite,
      onSurface: DietWiseColors.textPrimary,
      error: error,
      onError: Colors.white,
      outline: DietWiseColors.pastelBorder,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: DietWiseColors.cardWhite,
      foregroundColor: DietWiseColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: DietWiseColors.cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DietWiseColors.cardRadius),
        side: const BorderSide(color: DietWiseColors.pastelBorder),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DietWiseColors.cardWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DietWiseColors.inputRadius),
        borderSide: const BorderSide(color: DietWiseColors.pastelBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DietWiseColors.inputRadius),
        borderSide: const BorderSide(color: DietWiseColors.pastelBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DietWiseColors.inputRadius),
        borderSide: const BorderSide(color: DietWiseColors.buttonGray, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DietWiseColors.inputRadius),
        borderSide: const BorderSide(color: error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DietWiseColors.inputRadius),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      labelStyle: const TextStyle(color: DietWiseColors.textSecondary),
      hintStyle: const TextStyle(color: DietWiseColors.textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DietWiseColors.buttonGray,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DietWiseColors.inputRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: DietWiseColors.textSecondary,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return DietWiseColors.buttonGrayDark;
        }
        return Colors.transparent;
      }),
      side: const BorderSide(color: DietWiseColors.pastelBorder, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: DietWiseColors.cardWhite,
      selectedItemColor: DietWiseColors.textPrimary,
      unselectedItemColor: DietWiseColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: DietWiseColors.textPrimary,
      behavior: SnackBarBehavior.floating,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w300,
        letterSpacing: 1.2,
        color: DietWiseColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        color: DietWiseColors.textPrimary,
      ),
      bodyMedium: TextStyle(color: DietWiseColors.textSecondary),
    ),
  );
}
