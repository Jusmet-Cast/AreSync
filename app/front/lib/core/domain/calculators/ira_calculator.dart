import '../entities/agent_insight.dart';
import 'training_load.dart';

/// Insumos del Indice de Recuperacion (IRA). Espejo de "INPUTS QUE ACEPTA" de
/// AEGIS: lo que hoy entra a mano en el prototipo, entra por wearable el dia
/// que exista el adaptador real de `TelemetrySource`.
class IraInputs {
  const IraInputs({
    required this.rhrBpm,
    required this.sleepScore,
    required this.cargaSemanal,
    required this.vitalityScore7d,
  });

  final double rhrBpm;
  final double sleepScore;
  final double cargaSemanal;
  final double vitalityScore7d;
}

/// Calcula el IRA igual que AEGIS (`AEGIS.md` Paso 4): base 50 + 4 componentes
/// de 0 a 20/10, banda 0-100. No vive en Notion ni en un backend: es una
/// formula de dominio pura, para que training y nutrition puedan leerla sin
/// depender de que la sincronizacion este arriba.
class IraCalculator {
  const IraCalculator();

  int calcular(IraInputs inputs) {
    final int rhrScore = _rhrScore(inputs.rhrBpm);
    final int sleepScoreScore = _sleepScore(inputs.sleepScore);
    final int loadScore = _loadScore(TrainingLoadBand.clasificar(inputs.cargaSemanal));
    final int vitalityScore = _vitalityScore(inputs.vitalityScore7d);

    final int total = 50 + rhrScore + sleepScoreScore + loadScore + vitalityScore;
    return total.clamp(0, 100);
  }

  FlagLevel estadoDe(int iraScore) {
    if (iraScore >= 80) return FlagLevel.info; // Verde
    if (iraScore >= 60) return FlagLevel.amarillo;
    if (iraScore >= 40) return FlagLevel.naranja;
    return FlagLevel.rojo;
  }

  int _rhrScore(double rhr) {
    if (rhr < 50) return 20;
    if (rhr <= 60) return 10;
    // AEGIS.md no define el tramo 60-65 explicitamente (salta de "50-60:+10"
    // a ">65:0"). +5 interpola en vez de forzar un escalon brusco a 0.
    if (rhr <= 65) return 5;
    return 0;
  }

  int _sleepScore(double sleepScore) {
    if (sleepScore >= 80) return 20;
    if (sleepScore >= 70) return 10;
    return 0;
  }

  int _loadScore(TrainingLoadBand banda) => switch (banda) {
        TrainingLoadBand.low => 20,
        TrainingLoadBand.optimal => 15,
        TrainingLoadBand.high => 5,
        TrainingLoadBand.veryHigh => 0,
      };

  int _vitalityScore(double vitality) {
    if (vitality >= 50) return 10;
    if (vitality >= 25) return 5;
    return 0;
  }
}
