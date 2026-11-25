import 'package:flutter/material.dart';

/// Tokens de color de FitCodex.
///
/// Tres grupos con reglas distintas que NO se mezclan:
///
/// 1. Roles Material 3 — el cromo de la app.
/// 2. Series de datos — identidad en graficos. La paleta paso el validador de
///    separacion para daltonismo sobre fondo oscuro (peor par adyacente
///    delta-E 9.4, piso 8).
/// 3. Estado — bueno / atencion / critico. Reservados: un color de estado nunca
///    se reutiliza como serie, y nunca viaja solo (siempre con icono y texto).
abstract final class AppColors {
  // --- Material 3, esquema oscuro ---
  static const Color surface = Color(0xFF0E0F12);
  static const Color surfaceContainerLow = Color(0xFF15171C);
  static const Color surfaceContainer = Color(0xFF1A1D23);
  static const Color surfaceContainerHigh = Color(0xFF212530);
  static const Color outlineVariant = Color(0xFF2E323B);
  static const Color onSurface = Color(0xFFE7E9EE);
  static const Color onSurfaceVariant = Color(0xFF9BA1AE);

  /// Verde lima de marca. Se usa para accion primaria, indicador de navegacion
  /// y firma del coach. Nunca para datos ni para estado.
  static const Color primary = Color(0xFFC6F24E);
  static const Color onPrimary = Color(0xFF141A05);
  static const Color primaryContainer = Color(0xFF2C3A12);
  static const Color onPrimaryContainer = Color(0xFFDCFF86);
  static const Color secondaryContainer = Color(0xFF232833);

  // --- Series de datos ---
  static const Color series1 = Color(0xFF3987E5); // azul
  static const Color series2 = Color(0xFFD95926); // naranja
  static const Color series3 = Color(0xFF199E70); // aqua

  // --- Estado ---
  static const Color statusGood = Color(0xFF0CA30C);
  static const Color statusWarning = Color(0xFFFAB219);
  static const Color statusCritical = Color(0xFFD03B3B);
}
