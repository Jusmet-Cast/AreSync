import '../entities/agent_insight.dart';

/// Los 4 pilares del IAA (`MOMENTUM.md`), cada uno 0-100 ya calculado por
/// quien llama (entreno, nutricion, telemetria, PRs) — este calculador solo
/// promedia y banda, no sabe de donde salio cada score.
class IaaInputs {
  const IaaInputs({
    required this.scoreEntreno,
    required this.scoreNutricion,
    required this.scoreTelemetria,
    required this.scorePr,
  });

  final double scoreEntreno;
  final double scoreNutricion;
  final double scoreTelemetria;
  final double scorePr;
}

/// Promedio simple 1:1:1:1, igual que MOMENTUM declara hoy ("revisar si algun
/// pilar debe pesar mas una vez haya 4+ semanas de datos reales"). No se
/// adelanta esa recalibracion aca: cambiar la ponderacion sin datos para
/// sostenerla es inventar precision que no existe.
class IaaCalculator {
  const IaaCalculator();

  double calcular(IaaInputs inputs) {
    return (inputs.scoreEntreno +
            inputs.scoreNutricion +
            inputs.scoreTelemetria +
            inputs.scorePr) /
        4;
  }

  /// Mismo banding que el IRA de AEGIS, a proposito: "Verde/Amarillo/
  /// Naranja/Rojo" tiene que significar lo mismo en cualquier pilar.
  FlagLevel flagDe(double scoreTotal) {
    if (scoreTotal >= 80) return FlagLevel.info;
    if (scoreTotal >= 60) return FlagLevel.amarillo;
    if (scoreTotal >= 40) return FlagLevel.naranja;
    return FlagLevel.rojo;
  }
}
