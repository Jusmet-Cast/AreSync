/// Que tipo de ciclo es. Determina que metas tienen sentido mostrar y que
/// prioriza el coach: un `cut` no lee igual un deficit alto que un `bulk`.
enum ArcType {
  recomp,
  bulk,
  cut,
  hybrid,
  endurance,
  mental;

  /// Texto tal como vive en el select "Tipo" de Routes of Arcs en Notion.
  /// No se traduce: es el valor que el sistema agentico ya escribe ahi.
  String get nombreNotion => switch (this) {
        ArcType.recomp => 'Recomp Arc',
        ArcType.bulk => 'Bulk Arc',
        ArcType.cut => 'Cut Arc',
        ArcType.hybrid => 'Hybrid Arc',
        ArcType.endurance => 'Endurance Arc',
        ArcType.mental => 'Mental Arc',
      };
}

/// Estado del ciclo. Solo puede haber un Arc en `activo` a la vez: el resto
/// de la app (training, nutrition, telemetry) se reconfigura contra ESE.
enum ArcStatus { planeado, activo, completado }

/// Una meta numerica que el arc puede declarar o dejar sin setear.
///
/// No todo arc persigue todo: un Endurance Arc puede no tener meta de
/// proteina minima, y un Cut Arc puede no tener meta de VO2 Max. Forzar un
/// default (0, por ejemplo) rompe cualquier pantalla que calcule progreso
/// contra la meta. `null` es el estado correcto, no una ausencia a tapar.
class ArcGoals {
  const ArcGoals({
    this.pesoObjetivoKg,
    this.grasaObjetivoPorciento,
    this.masaLibreDeGrasaObjetivoKg,
    this.almiObjetivo,
    this.vatObjetivoCm2,
    this.proteinaMinG,
    this.proteinaMaxG,
    this.pasosObjetivo,
    this.sleepScoreObjetivo,
    this.sueñoOnsetObjetivo,
    this.vo2MaxObjetivo,
    this.vitalityScoreObjetivo,
  });

  final double? pesoObjetivoKg;
  final double? grasaObjetivoPorciento;
  final double? masaLibreDeGrasaObjetivoKg;
  final double? almiObjetivo;
  final double? vatObjetivoCm2;
  final double? proteinaMinG;
  final double? proteinaMaxG;
  final int? pasosObjetivo;
  final double? sleepScoreObjetivo;

  /// Texto libre ("00:00 regular") y no DateTime: es un habito objetivo, no
  /// un instante. Asi lo guarda Notion y asi se le muestra al usuario.
  final String? sueñoOnsetObjetivo;
  final double? vo2MaxObjetivo;
  final double? vitalityScoreObjetivo;

  /// Si no hay rango de proteina seteado, no hay barra que dibujar en Hoy.
  bool get tieneMetaDeProteina => proteinaMinG != null && proteinaMaxG != null;
}

/// El objetivo que el usuario setea y que gobierna todo lo demas.
///
/// Espejo de la base "Routes of Arcs" (AreSync/FitCodex en Notion): un Arc no
/// es un dato mas, es la unidad de planificacion. Training, nutrition y
/// telemetry no tienen metas propias — leen las de `goals` del arc activo. Un
/// `WorkingSet` sin arc activo no tiene contra que medirse, y por eso ninguna
/// pantalla de registro puede asumir un arc: tiene que resolverlo primero.
class Arc {
  const Arc({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.estado,
    required this.fechaInicio,
    required this.fechaFin,
    required this.descripcionBreve,
    required this.goals,
    this.pesoInicialKg,
    this.pesoFinalKg,
    this.deficitFaseActualKcal,
    this.progresoPorciento,
    this.scorePromedioAdherencia,
  });

  final String id;
  final String nombre;
  final ArcType tipo;
  final ArcStatus estado;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String descripcionBreve;
  final ArcGoals goals;

  final double? pesoInicialKg;
  final double? pesoFinalKg;

  /// Negativo en corte, positivo en volumen. Lo fija el agente de nutricion
  /// por fase, no es constante durante todo el arc.
  final int? deficitFaseActualKcal;

  /// Ya viene calculado por Notion (formula), no se recalcula en el cliente:
  /// asi ambos lados del sistema (chat agentico y app) muestran el mismo
  /// numero siempre.
  final double? progresoPorciento;

  /// Rollup del promedio de "Score Total (IAA)" sobre el Adherence Log
  /// relacionado. Null hasta que exista al menos una entrada de adherencia.
  final double? scorePromedioAdherencia;

  int get duracionDias => fechaFin.difference(fechaInicio).inDays;

  int get diasTranscurridos {
    final int dias = DateTime.now().difference(fechaInicio).inDays;
    return dias.clamp(0, duracionDias);
  }

  bool get estaActivo => estado == ArcStatus.activo;
}
