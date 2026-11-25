import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dos familias con roles separados.
///
/// Space Grotesk para numeros y titulos: tiene caracter tecnico y sus cifras
/// se leen bien en tamano grande. Plus Jakarta Sans para texto corrido.
///
/// PENDIENTE antes de produccion: empaquetar los .ttf como assets. google_fonts
/// los descarga en runtime y esta app tiene que arrancar en un gimnasio sin
/// senal.
abstract final class AppTypography {
  static TextTheme build(TextTheme base) {
    final TextTheme cuerpo = GoogleFonts.plusJakartaSansTextTheme(base);
    final TextStyle display = GoogleFonts.spaceGrotesk();

    return cuerpo.copyWith(
      displayLarge: display.copyWith(
        fontSize: 46,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.4,
      ),
      headlineMedium: display.copyWith(
        fontSize: 27,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
      ),
      titleLarge: display.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      labelSmall: cuerpo.labelSmall?.copyWith(
        fontSize: 10,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Estilo para cifras que se comparan en columna (tablas, ejes). Fuera de
  /// esos casos se usan cifras proporcionales: las tabulares hacen que un
  /// numero grande se vea suelto.
  static TextStyle tabular({
    required double size,
    FontWeight weight = FontWeight.w600,
    Color? color,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }
}
