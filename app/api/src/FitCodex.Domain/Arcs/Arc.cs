namespace FitCodex.Domain.Arcs;

/// <summary>
/// El objetivo que el usuario setea y que gobierna todo lo demas.
///
/// Training, nutrition y telemetry no tienen metas propias: leen las de este
/// arc. Un registro sin arc activo no tiene contra que medirse, y por eso
/// ninguna operacion de cierre puede asumir uno — tiene que resolverlo.
/// </summary>
public sealed class Arc
{
    private readonly List<ArcGoal> _goals = [];
    private readonly List<ArcPhase> _phases = [];

    private Arc()
    {
    }

    public Arc(
        Guid userId,
        string name,
        ArcType type,
        DateOnly startDate,
        DateOnly endDate,
        string? shortDescription = null)
    {
        if (endDate <= startDate)
        {
            throw new ArgumentException("El fin del arc tiene que ser posterior a su inicio.", nameof(endDate));
        }

        Id = Guid.NewGuid();
        UserId = userId;
        Name = name;
        Type = type;
        Status = ArcStatus.Planned;
        StartDate = startDate;
        EndDate = endDate;
        ShortDescription = shortDescription;
    }

    public Guid Id { get; private set; }
    public Guid UserId { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public ArcType Type { get; private set; }
    public ArcStatus Status { get; private set; }
    public DateOnly StartDate { get; private set; }
    public DateOnly EndDate { get; private set; }
    public string? ShortDescription { get; private set; }

    public decimal? InitialWeightKg { get; private set; }
    public decimal? FinalWeightKg { get; private set; }

    /// <summary>
    /// Deficit (negativo) o superavit (positivo) de la FASE vigente, no del
    /// arc entero. El cierre diario lo usa para decidir si el balance del dia
    /// coincide con lo que esa fase pedia.
    /// </summary>
    public int? PhaseDeficitKcal { get; private set; }

    public IReadOnlyCollection<ArcGoal> Goals => _goals;
    public IReadOnlyCollection<ArcPhase> Phases => _phases;

    public int DurationDays => EndDate.DayNumber - StartDate.DayNumber;

    public bool IsActive => Status == ArcStatus.Active;

    public int ElapsedDays(DateOnly today) =>
        Math.Clamp(today.DayNumber - StartDate.DayNumber, 0, DurationDays);

    /// <summary>
    /// Semana del ciclo (1-based) para una fecha. Es el <c>S</c> del
    /// identificador de sesion <c>D{dia}S{semana}{ArcCode}</c>.
    /// </summary>
    public int WeekOf(DateOnly date) => (date.DayNumber - StartDate.DayNumber) / 7 + 1;

    /// <summary>
    /// Dia dentro de la semana del ciclo (1-based). D1 es el dia de la semana
    /// en que arranco el arc, no necesariamente lunes.
    /// </summary>
    public int DayOf(DateOnly date) => (date.DayNumber - StartDate.DayNumber) % 7 + 1;

    public void Activate() => Status = ArcStatus.Active;

    public void Complete(decimal? finalWeightKg = null)
    {
        Status = ArcStatus.Completed;
        FinalWeightKg = finalWeightKg;
    }

    public void SetPhaseDeficit(int? kcal) => PhaseDeficitKcal = kcal;

    public void AddGoal(ArcGoal goal)
    {
        if (_goals.Any(g => g.Type == goal.Type))
        {
            throw new InvalidOperationException($"El arc ya tiene una meta de tipo {goal.Type}.");
        }

        _goals.Add(goal);
    }

    public ArcGoal? GoalFor(ArcGoalType type) => _goals.FirstOrDefault(g => g.Type == type);
}
