/// Veredicto sobre el balance energetico de un dia, espejo de la tabla de
/// AdheLog (`NOTION_DATA_REGISTRY.md` §3). Independiente del tipo de Arc: un
/// Bulk Arc espera `Surplus`, un Cut Arc espera `Deficit` — el veredicto
/// describe el balance real, el `TargetFit` dice si coincide con lo que esa
/// fase del Arc pedia.
enum BalanceVerdict {
  aggressiveDeficit,
  deficit,
  mildDeficit,
  maintenance,
  leanSurplus,
  surplus,
  aggressiveSurplus;

  static BalanceVerdict de(double energyBalanceKcal) {
    if (energyBalanceKcal < -750) return BalanceVerdict.aggressiveDeficit;
    if (energyBalanceKcal < -250) return BalanceVerdict.deficit;
    if (energyBalanceKcal < -100) return BalanceVerdict.mildDeficit;
    if (energyBalanceKcal <= 100) return BalanceVerdict.maintenance;
    if (energyBalanceKcal <= 300) return BalanceVerdict.leanSurplus;
    if (energyBalanceKcal <= 600) return BalanceVerdict.surplus;
    return BalanceVerdict.aggressiveSurplus;
  }

  String get etiqueta => switch (this) {
        BalanceVerdict.aggressiveDeficit => 'Deficit agresivo',
        BalanceVerdict.deficit => 'Deficit',
        BalanceVerdict.mildDeficit => 'Deficit leve',
        BalanceVerdict.maintenance => 'Mantenimiento',
        BalanceVerdict.leanSurplus => 'Superavit leve',
        BalanceVerdict.surplus => 'Superavit',
        BalanceVerdict.aggressiveSurplus => 'Superavit agresivo',
      };
}

enum TargetFit {
  onTarget,
  underTarget,
  overTarget;

  /// `energyBalance - phaseTarget`, igual que AdheLog. `phaseTarget` sale del
  /// Arc activo ("Deficit Fase Actual (kcal)"), nunca de una constante local
  /// — por eso lo recibe como parametro y no lo hardcodea este archivo.
  static TargetFit de({
    required double energyBalanceKcal,
    required int phaseTargetKcal,
  }) {
    final double diferencia = energyBalanceKcal - phaseTargetKcal;
    if (diferencia.abs() <= 150) return TargetFit.onTarget;
    return diferencia < 0 ? TargetFit.underTarget : TargetFit.overTarget;
  }

  String get etiqueta => switch (this) {
        TargetFit.onTarget => 'En objetivo',
        TargetFit.underTarget => 'Mas deficit del planeado',
        TargetFit.overTarget => 'Menos deficit del planeado',
      };
}

/// TDEE y balance del dia. `rmrKcal` sale del Arc/perfil (la TMR medida mas
/// reciente), nunca de Mifflin-St Jeor: ese calculo quedo invalidado por el
/// propio sistema real el dia que existio una medicion DXA — una formula
/// generica siempre pierde contra un dato medido cuando ambos estan
/// disponibles.
class BalanceVerdictCalculator {
  const BalanceVerdictCalculator();

  double tdee({
    required double rmrKcal,
    required double neatKcal,
    required double activeKcal,
  }) =>
      rmrKcal + neatKcal + activeKcal;

  double energyBalance({required double intakeKcal, required double tdeeKcal}) =>
      intakeKcal - tdeeKcal;
}
