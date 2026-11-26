namespace FitCodex.Domain.Adherence;

/// <summary>
/// Veredicto sobre el balance energetico de un dia. Independiente del tipo de
/// arc: un Bulk espera <c>Surplus</c> y un Cut espera <c>Deficit</c> — el
/// veredicto describe lo que paso, y <see cref="TargetFit"/> dice si coincide
/// con lo que la fase vigente pedia.
/// </summary>
public enum BalanceVerdict
{
    AggressiveDeficit,
    Deficit,
    MildDeficit,
    Maintenance,
    LeanSurplus,
    Surplus,
    AggressiveSurplus
}

public enum TargetFit
{
    OnTarget,
    UnderTarget,
    OverTarget
}

/// <summary>
/// Balance energetico del periodo. La base replica estas mismas bandas en la
/// vista <c>adherence.AdherenceEntryBalance</c> y el cliente en
/// <c>BalanceVerdictCalculator</c>.
/// </summary>
public static class EnergyBalance
{
    /// <summary>
    /// <paramref name="rmrKcal"/> sale de la TMR medida mas reciente, nunca de
    /// Mifflin-St Jeor: una formula generica siempre pierde contra una
    /// medicion real cuando ambas estan disponibles.
    /// </summary>
    public static decimal Tdee(decimal rmrKcal, decimal neatKcal, decimal activeKcal, int dayCount = 1)
    {
        if (dayCount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(dayCount), "El periodo tiene que cubrir al menos un dia.");
        }

        return rmrKcal + neatKcal + activeKcal / dayCount;
    }

    public static decimal Balance(decimal intakeKcal, decimal tdeeKcal) => intakeKcal - tdeeKcal;

    public static BalanceVerdict VerdictFor(decimal balanceKcal) => balanceKcal switch
    {
        < -750 => BalanceVerdict.AggressiveDeficit,
        < -250 => BalanceVerdict.Deficit,
        < -100 => BalanceVerdict.MildDeficit,
        <= 100 => BalanceVerdict.Maintenance,
        <= 300 => BalanceVerdict.LeanSurplus,
        <= 600 => BalanceVerdict.Surplus,
        _ => BalanceVerdict.AggressiveSurplus
    };

    /// <summary>
    /// <paramref name="phaseTargetKcal"/> sale de la fase vigente del arc, no
    /// de una constante: por eso entra como parametro.
    /// </summary>
    public static TargetFit FitFor(decimal balanceKcal, int phaseTargetKcal)
    {
        var difference = balanceKcal - phaseTargetKcal;

        if (Math.Abs(difference) <= 150)
        {
            return TargetFit.OnTarget;
        }

        return difference < 0 ? TargetFit.UnderTarget : TargetFit.OverTarget;
    }
}
