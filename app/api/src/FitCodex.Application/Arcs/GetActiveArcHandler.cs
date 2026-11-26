using FitCodex.Domain.Arcs;

namespace FitCodex.Application.Arcs;

/// <summary>
/// Resuelve el arc vigente de un usuario. Es la primera consulta de casi
/// cualquier flujo: sin arc activo no hay metas contra las que medir nada, y
/// la respuesta correcta es decirlo, no devolver un dashboard vacio.
/// </summary>
public sealed class GetActiveArcHandler(IArcRepository arcs)
{
    public async Task<ActiveArcResult?> HandleAsync(Guid userId, DateOnly today, CancellationToken cancellationToken = default)
    {
        var arc = await arcs.GetActiveAsync(userId, cancellationToken);

        if (arc is null)
        {
            return null;
        }

        return new ActiveArcResult(
            arc.Id,
            arc.Name,
            arc.Type,
            arc.StartDate,
            arc.EndDate,
            arc.DurationDays,
            arc.ElapsedDays(today),
            arc.WeekOf(today),
            arc.DayOf(today),
            arc.PhaseDeficitKcal);
    }
}

public sealed record ActiveArcResult(
    Guid Id,
    string Name,
    ArcType Type,
    DateOnly StartDate,
    DateOnly EndDate,
    int DurationDays,
    int ElapsedDays,
    int WeekOfArc,
    int DayOfWeekInArc,
    int? PhaseDeficitKcal);
