using FitCodex.Domain.Energy;
using FitCodex.Domain.Profiles;
using FitCodex.Domain.Targets;

namespace FitCodex.Domain.Tests;

public class TargetEngineAdaptiveTests
{
    private static readonly DateOnly Today = new(2026, 11, 26);

    private static BodyComposition Baseline() =>
        new(80, 175, BiologicalSex.Male, 23, BodyCompositionMethod.Dxa, Today, bodyFatPercent: 20);

    private static ObjectiveRequest Request() => new()
    {
        Objective = TrainingObjective.FatLoss,
        ActivityLevel = ActivityLevel.ModeratelyActive
    };

    private static TdeeEstimate Observed(decimal kcal, decimal confidence = 1m) => new()
    {
        Kcal = kcal,
        Source = TdeeSource.Observed,
        Confidence = confidence,
        DaysOfData = 30,
        IntakeCoverage = 0.95m,
        Warnings = []
    };

    [Fact]
    public void A_trustworthy_observation_replaces_the_activity_multiplier()
    {
        var fromFormula = TargetEngine.Derive(Baseline(), Request(), Today);
        var fromObserved = TargetEngine.Derive(Baseline(), Request(), Today, Observed(3100));

        Assert.NotEqual(fromFormula.MaintenanceKcal, fromObserved.MaintenanceKcal);
        Assert.Equal(3100m, fromObserved.MaintenanceKcal);
        Assert.Equal(TdeeSource.Observed, fromObserved.TdeeSource);
    }

    [Fact]
    public void A_higher_observed_expenditure_raises_the_calorie_target()
    {
        // Alguien que gasta mas de lo que la tabla supone no tiene por que
        // comer de menos: ese es exactamente el error que esto corrige.
        var low = TargetEngine.Derive(Baseline(), Request(), Today, Observed(2400));
        var high = TargetEngine.Derive(Baseline(), Request(), Today, Observed(3200));

        Assert.True(high.TargetKcal > low.TargetKcal);
    }

    [Fact]
    public void An_untrustworthy_observation_is_ignored()
    {
        var implausible = new TdeeEstimate
        {
            Kcal = 1100,
            Source = TdeeSource.Blended,
            Confidence = 0.2m,
            DaysOfData = 30,
            IntakeCoverage = 0.4m,
            Warnings = [TdeeWarning.ImplausiblyLow]
        };

        var fromFormula = TargetEngine.Derive(Baseline(), Request(), Today);
        var withBadData = TargetEngine.Derive(Baseline(), Request(), Today, implausible);

        Assert.Equal(fromFormula.MaintenanceKcal, withBadData.MaintenanceKcal);
        Assert.Equal(TdeeSource.Formula, withBadData.TdeeSource);
    }

    [Fact]
    public void Target_confidence_is_capped_by_its_weakest_link()
    {
        // Composicion perfecta (DXA, 1.0) pero gasto apenas observado (0.4):
        // el target no puede presumir mas confianza que la del gasto.
        var target = TargetEngine.Derive(Baseline(), Request(), Today, Observed(2900, confidence: 0.4m));

        Assert.Equal(0.4m, target.Confidence);
    }

    [Fact]
    public void The_whole_chain_runs_from_raw_measurements_to_a_target()
    {
        // Recorrido completo: cinta metrica -> grasa corporal -> composicion
        // -> seis semanas de peso e ingesta -> gasto real -> targets.
        var bodyFat = NavyBodyFat.Estimate(
            BiologicalSex.Male, heightCm: 175, neckCm: 37.1m, waistCm: 88m);

        var baseline = new BodyComposition(
            weightKg: 85, heightCm: 175, sex: BiologicalSex.Male, age: 30,
            method: BodyCompositionMethod.Navy, measuredOn: Today, bodyFatPercent: bodyFat);

        var records = Enumerable.Range(0, 42)
            .Select(day => new DailyEnergyRecord(
                Today.AddDays(-42 + day),
                85m - 0.5m * day / 7m,
                2300m))
            .ToList();

        var tdee = AdaptiveTdee.Estimate(
            records,
            formulaTdeeKcal: baseline.BasalMetabolicRateKcal * ActivityLevel.LightlyActive.Multiplier(),
            basalMetabolicRateKcal: baseline.BasalMetabolicRateKcal);

        var target = TargetEngine.Derive(
            baseline,
            new ObjectiveRequest
            {
                Objective = TrainingObjective.FatLoss,
                ActivityLevel = ActivityLevel.LightlyActive
            },
            Today,
            tdee);

        Assert.Equal(TdeeSource.Observed, target.TdeeSource);
        Assert.InRange(target.MaintenanceKcal, 2750m, 2950m);
        Assert.True(target.TargetKcal < target.MaintenanceKcal);
        Assert.True(target.ProteinG.Min > 100m);

        // Navy, no DXA: la confianza lo refleja y no finge precision.
        Assert.True(target.Confidence <= 0.7m);
    }
}
