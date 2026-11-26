using FitCodex.Domain.Adherence;

namespace FitCodex.Domain.Tests;

public class EnergyBalanceTests
{
    [Theory]
    [InlineData(-800, BalanceVerdict.AggressiveDeficit)]
    [InlineData(-750, BalanceVerdict.Deficit)]
    [InlineData(-450, BalanceVerdict.Deficit)]
    [InlineData(-250, BalanceVerdict.MildDeficit)]
    [InlineData(-100, BalanceVerdict.Maintenance)]
    [InlineData(0, BalanceVerdict.Maintenance)]
    [InlineData(100, BalanceVerdict.Maintenance)]
    [InlineData(300, BalanceVerdict.LeanSurplus)]
    [InlineData(600, BalanceVerdict.Surplus)]
    [InlineData(601, BalanceVerdict.AggressiveSurplus)]
    public void VerdictFor_classifies_balance(decimal balance, BalanceVerdict expected) =>
        Assert.Equal(expected, EnergyBalance.VerdictFor(balance));

    [Fact]
    public void Tdee_divides_active_kcal_across_the_period()
    {
        // Las calorias activas de una semana entran como total del periodo:
        // sin dividirlas, un cierre semanal reporta el gasto de 7 dias como
        // si fuera de uno.
        var weekly = EnergyBalance.Tdee(rmrKcal: 1700, neatKcal: 200, activeKcal: 3500, dayCount: 7);

        Assert.Equal(2400m, weekly);
    }

    [Fact]
    public void Tdee_rejects_an_empty_period() =>
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            EnergyBalance.Tdee(rmrKcal: 1700, neatKcal: 200, activeKcal: 500, dayCount: 0));

    [Theory]
    [InlineData(-450, -450, TargetFit.OnTarget)]
    [InlineData(-600, -450, TargetFit.OnTarget)]   // justo en el borde de 150
    [InlineData(-650, -450, TargetFit.UnderTarget)]
    [InlineData(-200, -450, TargetFit.OverTarget)]
    [InlineData(-300, -450, TargetFit.OnTarget)]
    public void FitFor_compares_against_the_phase_target(decimal balance, int phaseTarget, TargetFit expected) =>
        Assert.Equal(expected, EnergyBalance.FitFor(balance, phaseTarget));

    [Fact]
    public void FitFor_works_for_a_bulk_with_a_positive_target()
    {
        // El mismo calculo tiene que servir para un arc de volumen: lo que se
        // compara es la distancia al objetivo, no su signo.
        Assert.Equal(TargetFit.OnTarget, EnergyBalance.FitFor(balanceKcal: 350, phaseTargetKcal: 300));
        Assert.Equal(TargetFit.UnderTarget, EnergyBalance.FitFor(balanceKcal: 50, phaseTargetKcal: 300));
    }
}
