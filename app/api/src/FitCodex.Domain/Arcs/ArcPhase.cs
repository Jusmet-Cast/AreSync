namespace FitCodex.Domain.Arcs;

/// <summary>
/// Una fase del arc. El deficit, los pasos y el sueño objetivo cambian de
/// fase en fase: tratarlos como constantes del arc entero fue lo que obligaba
/// a editar el objetivo a mano cada vez que el ciclo avanzaba.
/// </summary>
public sealed class ArcPhase
{
    private ArcPhase()
    {
    }

    public ArcPhase(int phaseNumber, string name, int weekStart, int weekEnd)
    {
        if (weekEnd < weekStart)
        {
            throw new ArgumentException("La semana final no puede ser anterior a la inicial.", nameof(weekEnd));
        }

        Id = Guid.NewGuid();
        PhaseNumber = phaseNumber;
        Name = name;
        WeekStart = weekStart;
        WeekEnd = weekEnd;
        Status = ArcPhaseStatus.Planned;
    }

    public Guid Id { get; private set; }
    public Guid ArcId { get; private set; }
    public int PhaseNumber { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public int WeekStart { get; private set; }
    public int WeekEnd { get; private set; }
    public DateOnly? StartDate { get; private set; }
    public DateOnly? EndDate { get; private set; }
    public int? DeficitKcal { get; private set; }
    public int? StepsGoal { get; private set; }
    public string? SleepGoalText { get; private set; }
    public int? CardioSessionsPerWeek { get; private set; }
    public ArcPhaseStatus Status { get; private set; }

    public bool Covers(int weekOfArc) => weekOfArc >= WeekStart && weekOfArc <= WeekEnd;

    public void Close() => Status = ArcPhaseStatus.Closed;
}
