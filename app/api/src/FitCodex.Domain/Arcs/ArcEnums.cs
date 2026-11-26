namespace FitCodex.Domain.Arcs;

/// <summary>
/// Determina que metas tienen sentido y que prioriza el coach: un Cut no lee
/// igual un deficit alto que un Bulk.
/// </summary>
public enum ArcType
{
    Recomp,
    Bulk,
    Cut,
    Hybrid,
    Endurance,
    Mental
}

/// <summary>
/// Solo puede haber un arc Active por usuario a la vez — lo garantiza un
/// indice filtrado en la base, no solo esta convencion.
/// </summary>
public enum ArcStatus
{
    Planned,
    Active,
    Completed
}

public enum ArcGoalType
{
    WeightKg,
    BodyFatPercent,
    LeanMassKg,
    Almi,
    VatCm2,
    ProteinMinG,
    ProteinMaxG,
    Steps,
    SleepScore,
    SleepOnset,
    Vo2Max,
    VitalityScore
}

public enum ArcPhaseStatus
{
    Planned,
    Active,
    Closed
}
