namespace FitCodex.Domain.Targets;

/// <summary>
/// Que persigue el usuario. Es lo que la conversacion de onboarding tiene que
/// resolver antes de que el sistema pueda fijar un solo numero: el mismo
/// cuerpo con el mismo punto de partida necesita targets opuestos segun esto.
/// </summary>
public enum TrainingObjective
{
    FatLoss,
    MuscleGain,
    Recomposition,
    Performance,
    Maintenance
}

/// <summary>
/// Cuanta prisa acepta el usuario. No es cosmetico: define el tamaño del
/// deficit o superavit, y con el, cuanto musculo se arriesga a perder o
/// cuanta grasa a ganar.
/// </summary>
public enum Aggressiveness
{
    Conservative,
    Moderate,
    Aggressive
}

/// <summary>
/// Cuanto entrena y se mueve la persona. Multiplica el metabolismo basal
/// para estimar el gasto total mientras no haya datos reales de wearable ni
/// una tendencia de peso de la cual derivarlo.
/// </summary>
public enum ActivityLevel
{
    Sedentary,
    LightlyActive,
    ModeratelyActive,
    VeryActive,
    AthleteLevel
}

public static class ActivityLevels
{
    /// <summary>
    /// Multiplicadores estandar sobre el metabolismo basal. Son una muleta
    /// hasta tener dos semanas de peso e ingesta reales: a partir de ahi el
    /// gasto se deriva de la tendencia observada, que siempre le gana a un
    /// multiplicador de tabla.
    /// </summary>
    public static decimal Multiplier(this ActivityLevel level) => level switch
    {
        ActivityLevel.Sedentary => 1.2m,
        ActivityLevel.LightlyActive => 1.375m,
        ActivityLevel.ModeratelyActive => 1.55m,
        ActivityLevel.VeryActive => 1.725m,
        ActivityLevel.AthleteLevel => 1.9m,
        _ => 1.2m
    };
}
