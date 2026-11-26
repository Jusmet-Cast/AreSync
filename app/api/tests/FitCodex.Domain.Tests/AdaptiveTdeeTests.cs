using FitCodex.Domain.Energy;

namespace FitCodex.Domain.Tests;

public class AdaptiveTdeeTests
{
    private static readonly DateOnly Start = new(2026, 10, 1);

    /// <summary>
    /// Genera una serie realista: el peso cae de forma lineal pero cada
    /// pesaje trae ruido reproducible, como pasa en una balanza de verdad.
    /// </summary>
    private static List<DailyEnergyRecord> Series(
        int days,
        decimal startWeightKg,
        decimal weeklyChangeKg,
        decimal intakeKcal,
        decimal noiseKg = 0.3m,
        int logEveryNDays = 1)
    {
        var records = new List<DailyEnergyRecord>();

        for (var day = 0; day < days; day++)
        {
            var trueWeight = startWeightKg + weeklyChangeKg * day / 7m;

            // Ruido deterministico: alterna signo para no sesgar la media.
            var noise = (day % 3 - 1) * noiseKg;

            records.Add(new DailyEnergyRecord(
                Start.AddDays(day),
                trueWeight + noise,
                day % logEveryNDays == 0 ? intakeKcal : null));
        }

        return records;
    }

    [Fact]
    public void Falls_back_to_the_formula_before_the_minimum_window()
    {
        var records = Series(days: 7, startWeightKg: 80, weeklyChangeKg: -0.5m, intakeKcal: 2000);

        var estimate = AdaptiveTdee.Estimate(records, formulaTdeeKcal: 2500, basalMetabolicRateKcal: 1700);

        Assert.Equal(TdeeSource.Formula, estimate.Source);
        Assert.Equal(2500m, estimate.Kcal);
        Assert.Contains(TdeeWarning.InsufficientData, estimate.Warnings);
        Assert.False(estimate.IsTrustworthy);
    }

    [Fact]
    public void Recovers_the_real_expenditure_from_intake_and_trend()
    {
        // Come 2.000 y baja 0.5 kg por semana => gasta ~2.550.
        // (0.5 kg x 7700 kcal = 3850 kcal por semana = 550 por dia)
        var records = Series(days: 42, startWeightKg: 80, weeklyChangeKg: -0.5m, intakeKcal: 2000, noiseKg: 0m);

        var estimate = AdaptiveTdee.Estimate(records, formulaTdeeKcal: 2200, basalMetabolicRateKcal: 1700);

        Assert.Equal(TdeeSource.Observed, estimate.Source);
        Assert.InRange(estimate.Kcal, 2450m, 2650m);
    }

    [Fact]
    public void The_observed_value_overrides_a_wrong_formula()
    {
        // La formula dice 2.200 pero la realidad dice ~2.550. Ese hueco es
        // justamente la razon de existir de todo esto.
        var records = Series(days: 42, startWeightKg: 80, weeklyChangeKg: -0.5m, intakeKcal: 2000, noiseKg: 0m);

        var estimate = AdaptiveTdee.Estimate(records, formulaTdeeKcal: 2200, basalMetabolicRateKcal: 1700);

        Assert.True(estimate.Kcal > 2400m);
    }

    [Fact]
    public void Detects_expenditure_in_someone_who_is_gaining()
    {
        // Come 3.000 y sube 0.25 kg por semana => gasta ~2.725.
        var records = Series(days: 42, startWeightKg: 70, weeklyChangeKg: 0.25m, intakeKcal: 3000, noiseKg: 0m);

        var estimate = AdaptiveTdee.Estimate(records, formulaTdeeKcal: 2600, basalMetabolicRateKcal: 1650);

        Assert.InRange(estimate.Kcal, 2650m, 2800m);
        Assert.True(estimate.ObservedWeeklyChangeKg > 0);
    }

    [Fact]
    public void A_stable_weight_means_intake_equals_expenditure()
    {
        var records = Series(days: 42, startWeightKg: 75, weeklyChangeKg: 0m, intakeKcal: 2300, noiseKg: 0m);

        var estimate = AdaptiveTdee.Estimate(records, formulaTdeeKcal: 2000, basalMetabolicRateKcal: 1600);

        Assert.InRange(estimate.Kcal, 2250m, 2350m);
    }

    [Fact]
    public void Flags_an_expenditure_below_the_basal_rate_instead_of_trusting_it()
    {
        // El caso clasico: registra 1.200 kcal y el peso no se mueve. El
        // cuerpo no esta roto — hay comida que no se esta registrando.
        var records = Series(days: 42, startWeightKg: 85, weeklyChangeKg: 0m, intakeKcal: 1200, noiseKg: 0m);

        var estimate = AdaptiveTdee.Estimate(records, formulaTdeeKcal: 2400, basalMetabolicRateKcal: 1750);

        Assert.Contains(TdeeWarning.ImplausiblyLow, estimate.Warnings);
        Assert.False(estimate.IsTrustworthy);

        // Y no deja que ese numero arrastre la prescripcion.
        Assert.True(estimate.Kcal > 1800m);
    }

    [Fact]
    public void Sparse_intake_logging_lowers_confidence()
    {
        var complete = Series(days: 42, startWeightKg: 80, weeklyChangeKg: -0.5m, intakeKcal: 2000, noiseKg: 0m);
        var sparse = Series(days: 42, startWeightKg: 80, weeklyChangeKg: -0.5m, intakeKcal: 2000, noiseKg: 0m, logEveryNDays: 3);

        var fromComplete = AdaptiveTdee.Estimate(complete, 2200, 1700);
        var fromSparse = AdaptiveTdee.Estimate(sparse, 2200, 1700);

        Assert.Contains(TdeeWarning.SparseIntakeLogging, fromSparse.Warnings);
        Assert.True(fromSparse.Confidence < fromComplete.Confidence);
    }

    [Fact]
    public void Confidence_grows_with_the_length_of_the_record()
    {
        var twoWeeks = Series(days: 16, startWeightKg: 80, weeklyChangeKg: -0.5m, intakeKcal: 2000, noiseKg: 0m);
        var fourWeeks = Series(days: 30, startWeightKg: 80, weeklyChangeKg: -0.5m, intakeKcal: 2000, noiseKg: 0m);

        var early = AdaptiveTdee.Estimate(twoWeeks, 2200, 1700);
        var later = AdaptiveTdee.Estimate(fourWeeks, 2200, 1700);

        Assert.True(later.Confidence > early.Confidence);
        Assert.Equal(TdeeSource.Blended, early.Source);
        Assert.Equal(TdeeSource.Observed, later.Source);
    }

    [Fact]
    public void A_noisy_scale_is_flagged_and_discounted()
    {
        var noisy = Series(days: 42, startWeightKg: 80, weeklyChangeKg: -0.5m, intakeKcal: 2000, noiseKg: 2.5m);

        var estimate = AdaptiveTdee.Estimate(noisy, 2200, 1700);

        Assert.Contains(TdeeWarning.HighWeightVariance, estimate.Warnings);
        Assert.True(estimate.Confidence < 1m);
    }
}

public class WeightTrendTests
{
    private static readonly DateOnly Start = new(2026, 10, 1);

    [Fact]
    public void Smooths_a_single_bad_weigh_in()
    {
        // Un dia de comida con sal no puede mover la tendencia dos kilos.
        var observations = new List<WeightObservation>();

        for (var day = 0; day < 10; day++)
        {
            var kg = day == 5 ? 82m : 80m;
            observations.Add(new WeightObservation(Start.AddDays(day), kg));
        }

        var trend = WeightTrend.From(observations);

        Assert.NotNull(trend.Latest);
        Assert.InRange(trend.Latest!.Value, 80m, 80.6m);
    }

    [Fact]
    public void Follows_a_real_sustained_change()
    {
        var observations = Enumerable.Range(0, 60)
            .Select(day => new WeightObservation(Start.AddDays(day), 80m - day * 0.05m))
            .ToList();

        var trend = WeightTrend.From(observations);

        Assert.NotNull(trend.Change);
        Assert.True(trend.Change < -2m);
        Assert.NotNull(trend.WeeklyChangeKg);
        Assert.InRange(trend.WeeklyChangeKg!.Value, -0.40m, -0.30m);
    }

    [Fact]
    public void Averages_several_weigh_ins_on_the_same_day()
    {
        var trend = WeightTrend.From(
        [
            new WeightObservation(Start, 80m),
            new WeightObservation(Start, 81m)
        ]);

        Assert.Equal(80.5m, trend.Latest);
    }

    [Fact]
    public void An_empty_series_has_no_trend()
    {
        var trend = WeightTrend.From([]);

        Assert.True(trend.IsEmpty);
        Assert.Null(trend.Change);
        Assert.Null(trend.WeeklyChangeKg);
    }

    [Fact]
    public void Rejects_an_invalid_smoothing_factor() =>
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            WeightTrend.From([new WeightObservation(Start, 80m)], smoothing: 1.5m));
}
