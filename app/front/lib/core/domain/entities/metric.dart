/// Que mide un dato de telemetria.
///
/// Es un tipo cerrado a proposito: si aparece una metrica nueva se agrega aca
/// y el analizador marca todos los `switch` que quedaron incompletos.
enum MetricType {
  sleepDuration,
  restingHeartRate,
  heartRateVariability,
  steps,
  bodyWeight,
  bodyFatPercentage,
  leanMass;

  /// Metricas que ninguna fuente esta obligada a publicar. El caso real:
  /// la Xiaomi global escribe sueno y pulso, pero no variabilidad.
  bool get puedeFaltar => this == MetricType.heartRateVariability;
}

/// De donde salio el dato.
///
/// FitCodex no habla con fabricantes: habla con los agregadores del sistema
/// operativo. Garmin, Polar, Oura, Whoop y Xiaomi escriben ahi, asi que
/// cambiar de wearable no obliga a tocar este enum.
///
/// `strava` no esta y no va a estar: su politica de API prohibe ingresar sus
/// datos al contexto de una IA, que es exactamente lo que hace el coach.
enum MetricSource {
  appleHealth(precision: 0.9),
  healthConnect(precision: 0.9),
  manual(precision: 0.5),

  /// Derivada por FitCodex cruzando otras metricas (por ejemplo la carga
  /// aguda/cronica). No viene de ningun dispositivo.
  computed(precision: 0.8);

  const MetricSource({required this.precision});

  /// Cuanto confiamos en esta fuente cuando dos reportan lo mismo.
  final double precision;
}

/// El modelo canonico. Todo dato de telemetria entra por aca, venga de donde
/// venga, y guarda su procedencia: sin `source` no se puede decidir cual gana
/// ante un duplicado, ni explicarle al usuario de donde salio el numero.
class Metric {
  const Metric({
    required this.type,
    required this.value,
    required this.unit,
    required this.recordedAt,
    required this.source,
    this.confidence = 1,
  });

  final MetricType type;
  final double value;
  final String unit;
  final DateTime recordedAt;
  final MetricSource source;

  /// 0..1. Distinto de `source.precision`: aquella es cuanto confiamos en la
  /// fuente en general, esta es cuanto confiamos en ESTA lectura puntual
  /// (por ejemplo una medicion de bioimpedancia mal hidratada).
  final double confidence;

  /// Peso con el que compite contra otra lectura de la misma metrica.
  double get peso => source.precision * confidence;

  @override
  String toString() =>
      'Metric(${type.name}: $value $unit, ${source.name}, $recordedAt)';
}
