namespace FitCodex.Domain.Adherence;

/// <summary>
/// Banda de severidad compartida por todo el sistema. Que "rojo" signifique
/// lo mismo venga del indice de recuperacion o del de adherencia es lo que
/// permite fusionarlos en una sola pantalla sin que el usuario tenga que
/// aprender una escala por pilar.
/// </summary>
public enum SeverityBand
{
    Green,
    Yellow,
    Orange,
    Red
}

public static class SeverityBands
{
    public static SeverityBand ForScore(decimal score) => score switch
    {
        >= 80 => SeverityBand.Green,
        >= 60 => SeverityBand.Yellow,
        >= 40 => SeverityBand.Orange,
        _ => SeverityBand.Red
    };
}

/// <summary>
/// Clasificacion de la carga semanal acumulada (suma de training load).
/// </summary>
public enum TrainingLoadBand
{
    Low,
    Optimal,
    High,
    VeryHigh
}

public static class TrainingLoadBands
{
    public static TrainingLoadBand ForWeeklyLoad(decimal weeklyLoad) => weeklyLoad switch
    {
        < 300 => TrainingLoadBand.Low,
        <= 450 => TrainingLoadBand.Optimal,
        <= 600 => TrainingLoadBand.High,
        _ => TrainingLoadBand.VeryHigh
    };
}

public readonly record struct RecoveryInputs(
    decimal RestingHeartRateBpm,
    decimal SleepScore,
    decimal WeeklyTrainingLoad,
    decimal VitalityScore);

/// <summary>
/// Indice de recuperacion: base 50 mas cuatro componentes, 0-100.
///
/// Es una formula de dominio pura a proposito: entreno y nutricion la
/// consultan sin depender de que la sincronizacion con el wearable este
/// arriba. Mismo calculo en el cliente (<c>IraCalculator</c>).
/// </summary>
public static class RecoveryIndex
{
    public static int Calculate(RecoveryInputs inputs)
    {
        var total = 50
            + RestingHeartRateScore(inputs.RestingHeartRateBpm)
            + SleepScoreComponent(inputs.SleepScore)
            + LoadScore(TrainingLoadBands.ForWeeklyLoad(inputs.WeeklyTrainingLoad))
            + VitalityScoreComponent(inputs.VitalityScore);

        return Math.Clamp(total, 0, 100);
    }

    public static SeverityBand BandFor(int score) => SeverityBands.ForScore(score);

    private static int RestingHeartRateScore(decimal rhr) => rhr switch
    {
        < 50 => 20,
        <= 60 => 10,
        // El protocolo original salta de "50-60" a ">65" sin definir el tramo
        // intermedio. +5 interpola en vez de forzar un escalon brusco a cero.
        <= 65 => 5,
        _ => 0
    };

    private static int SleepScoreComponent(decimal sleepScore) => sleepScore switch
    {
        >= 80 => 20,
        >= 70 => 10,
        _ => 0
    };

    private static int LoadScore(TrainingLoadBand band) => band switch
    {
        TrainingLoadBand.Low => 20,
        TrainingLoadBand.Optimal => 15,
        TrainingLoadBand.High => 5,
        _ => 0
    };

    private static int VitalityScoreComponent(decimal vitality) => vitality switch
    {
        >= 50 => 10,
        >= 25 => 5,
        _ => 0
    };
}

public readonly record struct AdherenceInputs(
    decimal TrainingScore,
    decimal NutritionScore,
    decimal TelemetryScore,
    decimal PrScore);

/// <summary>
/// Indice de adherencia: promedio simple de los cuatro pilares.
///
/// La ponderacion es 1:1:1:1 deliberadamente, no por falta de criterio:
/// cambiarla sin semanas de datos reales para calibrarla seria inventar una
/// precision que no existe.
/// </summary>
public static class AdherenceIndex
{
    public static decimal Calculate(AdherenceInputs inputs) =>
        (inputs.TrainingScore + inputs.NutritionScore + inputs.TelemetryScore + inputs.PrScore) / 4m;

    public static SeverityBand BandFor(decimal total) => SeverityBands.ForScore(total);
}
