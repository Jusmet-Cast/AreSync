/// Nivel de experiencia. No se vende ni se desbloquea con pago: se infiere de
/// datos objetivos (semanas de registro, consistencia, PRs documentados) o se
/// declara a mano por alguien que ya entrena hace años y no quiere empezar
/// desde cero. Ver `features/profile` para los criterios de inferencia.
enum ExperienceLevel {
  base,
  constante,
  serio;

  String get etiqueta => switch (this) {
        ExperienceLevel.base => 'Base',
        ExperienceLevel.constante => 'Constante',
        ExperienceLevel.serio => 'Serio',
      };
}

/// Unidades de peso que el usuario eligio mostrar. El dato interno siempre
/// vive en kg (Notion y el backend lo guardan asi); esto es solo
/// presentacion, para no obligar a nadie a pensar en libras.
enum UnidadPeso { kg, lb }

/// Quien usa la app. Generico a proposito: FitCodex nace de un solo usuario
/// (Justyn, via AreSync) pero el objetivo de este dominio es que cualquier
/// persona en cualquier fase de su entrenamiento pueda setear su propio Arc y
/// que el resto del sistema se adapte a el, no al reves.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.nombre,
    required this.nivel,
    required this.unidadPeso,
    this.arcActivoId,
    this.fechaNacimiento,
    this.alturaCm,
  });

  final String id;
  final String nombre;
  final ExperienceLevel nivel;
  final UnidadPeso unidadPeso;

  /// Null si todavia no seteo ningun Arc. Toda pantalla que dependa de metas
  /// tiene que manejar ese caso explicitamente, no asumir que siempre hay uno.
  final String? arcActivoId;

  final DateTime? fechaNacimiento;
  final double? alturaCm;

  int? get edad {
    final DateTime? nacimiento = fechaNacimiento;
    if (nacimiento == null) return null;
    final DateTime hoy = DateTime.now();
    int edad = hoy.year - nacimiento.year;
    final bool todaviaNoCumplioEsteAño =
        hoy.month < nacimiento.month ||
            (hoy.month == nacimiento.month && hoy.day < nacimiento.day);
    if (todaviaNoCumplioEsteAño) edad--;
    return edad;
  }

  bool get tieneArcActivo => arcActivoId != null;
}
