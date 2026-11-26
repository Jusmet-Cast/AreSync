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

    /// <summary>
    /// Bandas absolutas en kcal. Se conservan por compatibilidad con el
    /// ledger historico, que las usa, pero NO sirven para multiples usuarios:
    /// -500 kcal es un deficit severo en alguien de 55 kg y uno moderado en
    /// alguien de 100 kg. Para cualquier usuario nuevo usar
    /// <see cref="VerdictFor(decimal, decimal)"/>, que normaliza contra el
    /// gasto real de esa persona.
    /// </summary>
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
    /// Veredicto relativo al gasto de la persona. Las mismas fronteras que la
    /// version absoluta, pero expresadas como porcentaje del TDEE — asi un
    /// deficit "agresivo" significa el mismo esfuerzo fisiologico para
    /// cualquiera, que es lo que una app multi-usuario necesita.
    ///
    /// Las fronteras salen de reescalar las bandas originales contra un gasto
    /// de 2.500 kcal, que es el orden de magnitud para el que fueron
    /// pensadas: -750/2500 = -30%, -250/2500 = -10%, y asi.
    /// </summary>
    public static BalanceVerdict VerdictFor(decimal balanceKcal, decimal tdeeKcal)
    {
        if (tdeeKcal <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(tdeeKcal),
                "Sin gasto no hay con que comparar el balance.");
        }

        var ratio = balanceKcal / tdeeKcal;

        return ratio switch
        {
            < -0.30m => BalanceVerdict.AggressiveDeficit,
            < -0.10m => BalanceVerdict.Deficit,
            < -0.04m => BalanceVerdict.MildDeficit,
            <= 0.04m => BalanceVerdict.Maintenance,
            <= 0.12m => BalanceVerdict.LeanSurplus,
            <= 0.24m => BalanceVerdict.Surplus,
            _ => BalanceVerdict.AggressiveSurplus
        };
    }

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
