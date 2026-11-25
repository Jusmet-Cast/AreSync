enum TipoActividad {
  hiking,
  biking,
  alpinism,
  camping,
  canopy,
  espeleologia,
  trekking,
  running,
}

enum EstadoAventura { enPlaneacion, proximoDesafio, completado }

enum Dificultad { facil, moderada, dura, extrema }

/// Si la aventura es un reto personal o un evento de comunidad.
///
/// Es la distincion central del pilar: PATHFINDER en Notion solo modelaba
/// retos individuales (Adventures es de un solo usuario). Ac� se abre a
/// `community` para maratones, salidas grupales o carreras — eventos que
/// otros usuarios de la app pueden ver y sumarse, al estilo red social. Un
/// `Adventure` nunca es las dos cosas a la vez: si suma gente, es community.
enum AdventureKind { personal, community }

/// Un reto outdoor o evento, propio o de comunidad.
///
/// Espejo generalizado de la base "Adventures" de Notion (PATHFINDER). La
/// version personal es 1:1 con ese schema; la version community agrega lo
/// minimo para que funcione como evento social (cupo, organizador,
/// confirmados) sin inventar un dominio de red social completo todavia —
/// eso es trabajo futuro, no de hoy.
class Adventure {
  const Adventure({
    required this.id,
    required this.destino,
    required this.tipos,
    required this.estado,
    required this.dificultad,
    required this.duracionHoras,
    required this.fechaVisita,
    required this.kind,
    this.ubicacion,
    this.msnm,
    this.organizadorId,
    this.cupo,
    this.confirmados = const <String>[],
  });

  final String id;
  final String destino;
  final Set<TipoActividad> tipos;
  final EstadoAventura estado;
  final Dificultad dificultad;
  final double duracionHoras;
  final DateTime fechaVisita;
  final AdventureKind kind;

  final String? ubicacion;
  final double? msnm;

  /// Solo tiene sentido si `kind == community`. Quien la crea.
  final String? organizadorId;

  /// Cupo maximo de participantes. Null = sin limite declarado.
  final int? cupo;

  /// IDs de usuarios que confirmaron asistencia. Vacio en una aventura
  /// personal: no tiene a quien confirmarle a nadie mas que a uno mismo.
  final List<String> confirmados;

  bool get esComunitaria => kind == AdventureKind.community;

  bool get tieneCupoDisponible {
    final int? limite = cupo;
    if (limite == null) return true;
    return confirmados.length < limite;
  }

  /// Dias hasta la fecha de visita. Negativo si ya paso.
  int get diasRestantes => fechaVisita.difference(DateTime.now()).inDays;
}
