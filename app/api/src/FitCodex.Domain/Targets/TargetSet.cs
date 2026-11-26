using FitCodex.Domain.Energy;
using FitCodex.Domain.Profiles;

namespace FitCodex.Domain.Targets;

/// <summary>
/// Un rango objetivo. Casi nada en nutricion es un numero unico: decirle a
/// alguien "comé 173 g de proteina" finge una precision que ni la balanza ni
/// la tabla de composicion de alimentos sostienen.
/// </summary>
public readonly record struct TargetRange(decimal Min, decimal Max)
{
    public decimal Midpoint => (Min + Max) / 2m;

    public bool Contains(decimal value) => value >= Min && value <= Max;
}

/// <summary>
/// Por que un target quedo limitado. Si el motor recorto lo que el usuario
/// pidio, tiene que poder explicar cual fue el tope y no simplemente
/// devolver un numero mas chico sin aviso.
/// </summary>
public enum TargetConstraint
{
    /// <summary>El deficit se recorto para no bajar del piso metabolico.</summary>
    MetabolicFloor,

    /// <summary>El ritmo pedido superaba el maximo semanal seguro.</summary>
    MaxWeeklyRate,

    /// <summary>La grasa corporal ya esta cerca del minimo esencial.</summary>
    EssentialFatFloor,

    /// <summary>El punto de partida es un estimado visual, no una medicion.</summary>
    UnmeasuredBaseline,

    /// <summary>El plazo pedido no alcanza para la meta a un ritmo seguro.</summary>
    TimelineInfeasible
}

/// <summary>
/// Lo que el sistema deriva para un usuario concreto. Nada de esto se
/// hardcodea ni se copia de otro usuario: todo sale de su composicion
/// corporal, su objetivo y su nivel.
/// </summary>
public sealed record TargetSet
{
    public required decimal MaintenanceKcal { get; init; }
    public required decimal TargetKcal { get; init; }

    /// <summary>Negativo en deficit, positivo en superavit, 0 en mantenimiento.</summary>
    public required int DailyEnergyOffsetKcal { get; init; }

    public required TargetRange ProteinG { get; init; }
    public required TargetRange FatG { get; init; }
    public required TargetRange CarbsG { get; init; }

    public required int DailyStepGoal { get; init; }
    public required int SleepScoreGoal { get; init; }

    /// <summary>
    /// Cambio de peso esperado por semana, en kg. Negativo si se baja.
    /// Es lo que permite decirle al usuario si su plazo es realista ANTES de
    /// que invierta tres meses en descubrir que no lo era.
    /// </summary>
    public required decimal ExpectedWeeklyWeightChangeKg { get; init; }

    /// <summary>
    /// Confianza 0..1 heredada del metodo de medicion del punto de partida.
    /// Un target derivado de un estimado visual no vale lo mismo que uno
    /// derivado de un DXA, y la app tiene que mostrarlo.
    /// </summary>
    public required decimal Confidence { get; init; }

    public required BodyCompositionMethod BaselineMethod { get; init; }

    /// <summary>
    /// Si el gasto que sostiene estos targets salio de una tabla o de la
    /// evidencia real del usuario. Cambia como se le presenta el numero:
    /// "estimado segun tu perfil" no es lo mismo que "medido en tus ultimas
    /// cuatro semanas".
    /// </summary>
    public TdeeSource TdeeSource { get; init; } = TdeeSource.Formula;

    public IReadOnlyList<TargetConstraint> Constraints { get; init; } = [];

    /// <summary>
    /// Cuando conviene volver a medir y recalcular. Un target derivado de una
    /// composicion de hace tres meses describe a una persona que ya no existe.
    /// </summary>
    public required DateOnly RecalculateAfter { get; init; }

    public bool IsDeficit => DailyEnergyOffsetKcal < 0;

    public bool RequiresProfessionalReview =>
        Constraints.Contains(TargetConstraint.EssentialFatFloor)
        || Constraints.Contains(TargetConstraint.MetabolicFloor);
}
