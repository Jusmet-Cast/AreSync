/// Clasificacion de carga semanal acumulada (suma de Training Load de la
/// semana). Un solo lugar para esta banda: la usan tanto el calculo del IRA
/// como cualquier pantalla que quiera decir "tu semana esta en zona Optima".
enum TrainingLoadBand {
  low,
  optimal,
  high,
  veryHigh;

  static TrainingLoadBand clasificar(double cargaSemanal) {
    if (cargaSemanal < 300) return TrainingLoadBand.low;
    if (cargaSemanal <= 450) return TrainingLoadBand.optimal;
    if (cargaSemanal <= 600) return TrainingLoadBand.high;
    return TrainingLoadBand.veryHigh;
  }

  /// Riesgo de sobreentrenamiento sostenido: 2+ semanas en `high` o una sola
  /// semana en `veryHigh`. Quien llama decide cuantas semanas lleva mirando.
  bool get requiereDeload =>
      this == TrainingLoadBand.veryHigh || this == TrainingLoadBand.high;
}
