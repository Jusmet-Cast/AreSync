/// Una serie efectiva registrada.
///
/// `rir` (repeticiones en reserva) no es opcional a proposito: es el dato que
/// permite derivar la carga de la proxima sesion sin adivinar. Si se deja
/// pasar como nulo, la periodizacion calcula sobre aire.
class WorkingSet {
  const WorkingSet({
    required this.numero,
    required this.pesoKg,
    required this.repeticiones,
    required this.rir,
    required this.registradaEn,
  });

  final int numero;
  final double pesoKg;
  final int repeticiones;
  final int rir;
  final DateTime registradaEn;

  /// Tonelaje de la serie. Suma del tonelaje semanal por grupo muscular es
  /// una de las entradas de la carga aguda/cronica.
  double get tonelaje => pesoKg * repeticiones;

  /// Solo cuentan para el rango de volumen semanal las series llevadas a 3
  /// repeticiones o menos de reserva. El calentamiento no estimula.
  bool get esEfectiva => rir <= 3;

  WorkingSet copyWith({double? pesoKg, int? repeticiones, int? rir}) {
    return WorkingSet(
      numero: numero,
      pesoKg: pesoKg ?? this.pesoKg,
      repeticiones: repeticiones ?? this.repeticiones,
      rir: rir ?? this.rir,
      registradaEn: registradaEn,
    );
  }
}
