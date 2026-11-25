/// 1RM estimado via la formula de Epley que usa FORGE (`FORGE.md` Paso 5):
/// `1RM = Carga x (1 + Reps/30)`. Se usa para detectar PR y para ubicar un
/// ejercicio en su zona de entrenamiento sin pedirle al usuario un test real
/// de una repeticion, que en la practica casi nadie hace de forma segura.
class OneRepMaxCalculator {
  const OneRepMaxCalculator();

  double estimar({required double pesoKg, required int repeticiones}) {
    return pesoKg * (1 + repeticiones / 30);
  }
}

/// Las 5 zonas de FORGE (`FORGE.md` Paso 1). `hipertrofia` es la zona
/// primaria: el resto existen para poder marcar cuando un ejercicio
/// principal se fue de rango, no para sugerir que todas pesan igual.
enum HypertrophyZone {
  fuerza,
  hibrido,
  hipertrofia,
  volumen,
  resistencia;

  static HypertrophyZone porRepeticiones(int reps) {
    if (reps <= 5) return HypertrophyZone.fuerza;
    if (reps <= 8) return HypertrophyZone.hibrido;
    if (reps <= 12) return HypertrophyZone.hipertrofia;
    if (reps <= 20) return HypertrophyZone.volumen;
    return HypertrophyZone.resistencia;
  }

  String get etiqueta => switch (this) {
        HypertrophyZone.fuerza => 'Fuerza',
        HypertrophyZone.hibrido => 'Hibrido',
        HypertrophyZone.hipertrofia => 'Hipertrofia',
        HypertrophyZone.volumen => 'Volumen',
        HypertrophyZone.resistencia => 'Resistencia',
      };

  /// Un ejercicio principal (sentadilla, press banca, peso muerto, remo...)
  /// fuera de hipertrofia/hibrido/fuerza es la señal que FORGE marca como
  /// FLAG en el Paso 1: "rangos > 20 reps en ejercicios principales".
  bool esRangoDeAislamientoAceptable(bool esEjercicioPrincipal) {
    if (!esEjercicioPrincipal) return true;
    return this != HypertrophyZone.resistencia;
  }
}
