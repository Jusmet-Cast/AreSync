namespace FitCodex.Domain.Training;

/// <summary>
/// 1RM estimado por la formula de Epley: <c>carga x (1 + reps/30)</c>. Se usa
/// para detectar PR y para ubicar un ejercicio en su zona de trabajo sin
/// pedirle al usuario un test real de una repeticion, que casi nadie hace de
/// forma segura.
///
/// La base replica este mismo calculo como columna calculada
/// (<c>training.ExerciseLog.EstimatedOneRmKg</c>) y el cliente Flutter lo
/// tiene en <c>OneRepMaxCalculator</c>. Los tres tienen que dar lo mismo.
/// </summary>
public static class OneRepMax
{
    public static decimal Estimate(decimal weightKg, int reps) =>
        weightKg * (1 + reps / 30m);
}

/// <summary>
/// Las cinco zonas de trabajo por rango de repeticiones. Hipertrofia es la
/// zona primaria; el resto existen para poder marcar cuando un ejercicio
/// principal se fue de rango.
/// </summary>
public enum HypertrophyZone
{
    Strength,
    Hybrid,
    Hypertrophy,
    Volume,
    Endurance
}

public static class HypertrophyZones
{
    public static HypertrophyZone ForReps(int reps) => reps switch
    {
        <= 5 => HypertrophyZone.Strength,
        <= 8 => HypertrophyZone.Hybrid,
        <= 12 => HypertrophyZone.Hypertrophy,
        <= 20 => HypertrophyZone.Volume,
        _ => HypertrophyZone.Endurance
    };

    /// <summary>
    /// Un ejercicio principal por encima de 20 repeticiones es la señal que
    /// hay que marcar: deja de ser estimulo de fuerza y pasa a resistencia
    /// sin que nadie lo haya decidido.
    /// </summary>
    public static bool IsOutOfRange(HypertrophyZone zone, bool isCompoundLift) =>
        isCompoundLift && zone == HypertrophyZone.Endurance;
}
