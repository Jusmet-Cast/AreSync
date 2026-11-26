namespace FitCodex.Domain.Energy;

/// <summary>
/// De donde salio el gasto que se esta usando. La app lo muestra: el usuario
/// tiene derecho a saber si su numero es una cuenta de tabla o su propio
/// metabolismo medido contra la realidad.
/// </summary>
public enum TdeeSource
{
    /// <summary>Multiplicador de actividad sobre el basal. Sin datos propios todavia.</summary>
    Formula,

    /// <summary>Mezcla de formula y observacion mientras se acumula evidencia.</summary>
    Blended,

    /// <summary>Derivado enteramente de la tendencia de peso contra la ingesta real.</summary>
    Observed
}

public enum TdeeWarning
{
    /// <summary>Pocos dias para que la tendencia signifique algo.</summary>
    InsufficientData,

    /// <summary>Faltan demasiados dias de ingesta registrada.</summary>
    SparseIntakeLogging,

    /// <summary>El peso oscila tanto que la tendencia no es confiable.</summary>
    HighWeightVariance,

    /// <summary>
    /// El gasto calculado quedo por debajo del metabolismo basal. Casi nunca
    /// significa un metabolismo roto: significa que falta comida sin registrar.
    /// </summary>
    ImplausiblyLow
}

public sealed record TdeeEstimate
{
    public required decimal Kcal { get; init; }
    public required TdeeSource Source { get; init; }

    /// <summary>0..1. Cuanta evidencia propia sostiene este numero.</summary>
    public required decimal Confidence { get; init; }

    public required int DaysOfData { get; init; }

    /// <summary>Proporcion de dias del periodo con ingesta registrada.</summary>
    public required decimal IntakeCoverage { get; init; }

    public decimal? ObservedWeeklyChangeKg { get; init; }

    public IReadOnlyList<TdeeWarning> Warnings { get; init; } = [];

    /// <summary>
    /// Si conviene mostrarle el numero al usuario como dato o solo usarlo
    /// internamente. Un gasto implausible no se muestra: se pide revisar el
    /// registro de comidas.
    /// </summary>
    public bool IsTrustworthy =>
        !Warnings.Contains(TdeeWarning.ImplausiblyLow)
        && !Warnings.Contains(TdeeWarning.InsufficientData);
}
