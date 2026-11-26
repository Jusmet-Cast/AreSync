namespace FitCodex.Domain.Arcs;

/// <summary>
/// Una meta del arc. Baseline y Stretch existen porque el sistema real los
/// usaba (en una tabla suelta dentro de la pagina del arc) aunque el schema
/// formal solo tenia el objetivo: sin baseline no hay progreso calculable,
/// solo distancia al objetivo.
/// </summary>
public sealed class ArcGoal
{
    private ArcGoal()
    {
    }

    public ArcGoal(
        ArcGoalType type,
        decimal? baselineValue = null,
        decimal? targetValue = null,
        decimal? stretchValue = null,
        string? targetText = null)
    {
        Id = Guid.NewGuid();
        Type = type;
        BaselineValue = baselineValue;
        TargetValue = targetValue;
        StretchValue = stretchValue;
        TargetText = targetText;
    }

    public Guid Id { get; private set; }
    public Guid ArcId { get; private set; }
    public ArcGoalType Type { get; private set; }
    public decimal? BaselineValue { get; private set; }
    public decimal? TargetValue { get; private set; }
    public decimal? StretchValue { get; private set; }

    /// <summary>
    /// Para metas que no son numericas puras (ej. SleepOnset = "00:00
    /// regular"): es un habito objetivo, no un instante.
    /// </summary>
    public string? TargetText { get; private set; }

    /// <summary>
    /// Progreso 0..1 entre el baseline y el objetivo. Null si falta alguno de
    /// los dos: sin baseline no se puede decir cuanto se avanzo, y devolver 0
    /// seria mentir con un numero.
    /// </summary>
    public decimal? ProgressFrom(decimal currentValue)
    {
        if (BaselineValue is not { } baseline || TargetValue is not { } target)
        {
            return null;
        }

        var span = target - baseline;
        if (span == 0)
        {
            return currentValue == target ? 1m : 0m;
        }

        var progress = (currentValue - baseline) / span;
        return Math.Clamp(progress, 0m, 1m);
    }
}
