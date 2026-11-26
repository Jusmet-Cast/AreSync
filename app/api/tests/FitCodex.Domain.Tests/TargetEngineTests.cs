using FitCodex.Domain.Profiles;
using FitCodex.Domain.Targets;

namespace FitCodex.Domain.Tests;

public class TargetEngineTests
{
    private static readonly DateOnly Today = new(2026, 11, 26);

    private static BodyComposition Baseline(
        decimal weightKg = 80,
        decimal heightCm = 175,
        BiologicalSex sex = BiologicalSex.Male,
        int age = 23,
        decimal? bodyFat = 20,
        BodyCompositionMethod method = BodyCompositionMethod.Dxa) =>
        new(weightKg, heightCm, sex, age, method, Today, bodyFat);

    private static ObjectiveRequest Request(
        TrainingObjective objective = TrainingObjective.FatLoss,
        Aggressiveness aggressiveness = Aggressiveness.Moderate,
        ActivityLevel activity = ActivityLevel.ModeratelyActive) =>
        new() { Objective = objective, ActivityLevel = activity, Aggressiveness = aggressiveness };

    [Fact]
    public void Two_users_with_the_same_objective_get_different_targets()
    {
        // El punto de todo esto: el target no es del objetivo, es de la persona.
        var small = TargetEngine.Derive(Baseline(weightKg: 55, heightCm: 160, sex: BiologicalSex.Female, bodyFat: 28), Request(), Today);
        var large = TargetEngine.Derive(Baseline(weightKg: 100, heightCm: 188, bodyFat: 28), Request(), Today);

        Assert.True(large.TargetKcal > small.TargetKcal);
        Assert.True(large.ProteinG.Min > small.ProteinG.Min);
        Assert.NotEqual(small.DailyEnergyOffsetKcal, large.DailyEnergyOffsetKcal);
    }

    [Fact]
    public void Protein_is_anchored_to_lean_mass_not_bodyweight()
    {
        // Mismo peso, composicion opuesta. Si la proteina saliera del peso
        // corporal, los dos recibirian la misma cifra — y para el de 40% de
        // grasa esa cifra no tiene sustento fisiologico.
        var lean = TargetEngine.Derive(Baseline(weightKg: 100, bodyFat: 12), Request(), Today);
        var heavy = TargetEngine.Derive(Baseline(weightKg: 100, bodyFat: 40), Request(), Today);

        Assert.True(lean.ProteinG.Min > heavy.ProteinG.Min);
    }

    [Fact]
    public void No_deficit_is_prescribed_at_the_essential_fat_floor()
    {
        var target = TargetEngine.Derive(
            Baseline(bodyFat: 7, sex: BiologicalSex.Male),
            Request(TrainingObjective.FatLoss, Aggressiveness.Aggressive),
            Today);

        Assert.Equal(0, target.DailyEnergyOffsetKcal);
        Assert.Contains(TargetConstraint.EssentialFatFloor, target.Constraints);
        Assert.True(target.RequiresProfessionalReview);
    }

    [Fact]
    public void The_essential_fat_floor_differs_by_sex()
    {
        // 13% es piso para una mujer y margen de sobra para un hombre.
        var female = TargetEngine.Derive(
            Baseline(sex: BiologicalSex.Female, bodyFat: 13),
            Request(TrainingObjective.FatLoss),
            Today);

        var male = TargetEngine.Derive(
            Baseline(sex: BiologicalSex.Male, bodyFat: 13),
            Request(TrainingObjective.FatLoss),
            Today);

        Assert.Equal(0, female.DailyEnergyOffsetKcal);
        Assert.True(male.DailyEnergyOffsetKcal < 0);
    }

    [Fact]
    public void Intake_never_drops_below_the_basal_metabolic_rate()
    {
        // Persona chica y sedentaria pidiendo lo mas agresivo posible: es el
        // caso donde un porcentaje de deficit sin piso te manda a comer menos
        // de lo que gastas en reposo.
        var baseline = Baseline(weightKg: 48, heightCm: 152, sex: BiologicalSex.Female, bodyFat: 30);

        var target = TargetEngine.Derive(
            baseline,
            Request(TrainingObjective.FatLoss, Aggressiveness.Aggressive, ActivityLevel.Sedentary),
            Today);

        Assert.True(target.TargetKcal >= baseline.BasalMetabolicRateKcal);
    }

    [Fact]
    public void Weekly_loss_is_capped_at_one_percent_of_bodyweight()
    {
        var target = TargetEngine.Derive(
            Baseline(weightKg: 60, bodyFat: 25),
            Request(TrainingObjective.FatLoss, Aggressiveness.Aggressive),
            Today);

        Assert.True(Math.Abs(target.ExpectedWeeklyWeightChangeKg) <= 0.60m);
    }

    [Fact]
    public void Recomposition_never_runs_a_steep_deficit()
    {
        var recomp = TargetEngine.Derive(Baseline(), Request(TrainingObjective.Recomposition, Aggressiveness.Aggressive), Today);
        var cut = TargetEngine.Derive(Baseline(), Request(TrainingObjective.FatLoss, Aggressiveness.Aggressive), Today);

        Assert.True(recomp.DailyEnergyOffsetKcal > cut.DailyEnergyOffsetKcal);
    }

    [Fact]
    public void Muscle_gain_produces_a_surplus_and_maintenance_produces_neither()
    {
        var bulk = TargetEngine.Derive(Baseline(), Request(TrainingObjective.MuscleGain), Today);
        var hold = TargetEngine.Derive(Baseline(), Request(TrainingObjective.Maintenance), Today);

        Assert.True(bulk.DailyEnergyOffsetKcal > 0);
        Assert.Equal(0, hold.DailyEnergyOffsetKcal);
        Assert.True(bulk.ExpectedWeeklyWeightChangeKg > 0);
    }

    [Fact]
    public void A_visual_estimate_lowers_confidence_and_is_flagged()
    {
        var target = TargetEngine.Derive(
            Baseline(method: BodyCompositionMethod.VisualEstimate, bodyFat: null),
            Request(),
            Today);

        Assert.Contains(TargetConstraint.UnmeasuredBaseline, target.Constraints);
        Assert.True(target.Confidence < 0.5m);
    }

    [Fact]
    public void A_dxa_baseline_carries_full_confidence()
    {
        var target = TargetEngine.Derive(Baseline(method: BodyCompositionMethod.Dxa), Request(), Today);

        Assert.Equal(1.0m, target.Confidence);
        Assert.DoesNotContain(TargetConstraint.UnmeasuredBaseline, target.Constraints);
    }

    [Fact]
    public void An_impossible_timeline_is_flagged_instead_of_silently_accepted()
    {
        var request = Request() with { TargetWeightKg = 70, DesiredWeeks = 4 };

        var target = TargetEngine.Derive(Baseline(weightKg: 90, bodyFat: 25), request, Today);

        Assert.Contains(TargetConstraint.TimelineInfeasible, target.Constraints);
    }

    [Fact]
    public void A_realistic_timeline_is_not_flagged()
    {
        var request = Request() with { TargetWeightKg = 86, DesiredWeeks = 12 };

        var target = TargetEngine.Derive(Baseline(weightKg: 90, bodyFat: 25), request, Today);

        Assert.DoesNotContain(TargetConstraint.TimelineInfeasible, target.Constraints);
    }

    [Fact]
    public void Macros_add_up_to_the_calorie_target()
    {
        var target = TargetEngine.Derive(Baseline(), Request(), Today);

        var kcalFromMacros = target.ProteinG.Midpoint * 4
                           + target.CarbsG.Midpoint * 4
                           + target.FatG.Midpoint * 9;

        Assert.InRange(kcalFromMacros, target.TargetKcal * 0.95m, target.TargetKcal * 1.05m);
    }

    [Fact]
    public void A_measured_rmr_wins_over_any_formula()
    {
        var estimated = Baseline(bodyFat: 20);
        var measured = new BodyComposition(80, 175, BiologicalSex.Male, 23,
            BodyCompositionMethod.Dxa, Today, bodyFatPercent: 20, measuredRmrKcal: 1900);

        Assert.NotEqual(estimated.BasalMetabolicRateKcal, measured.BasalMetabolicRateKcal);
        Assert.Equal(1900m, measured.BasalMetabolicRateKcal);
        Assert.Equal("measured", measured.BmrSource);
        Assert.Equal("katch_mcardle", estimated.BmrSource);
    }

    [Fact]
    public void Without_body_fat_the_estimate_falls_back_to_mifflin()
    {
        var unknown = Baseline(bodyFat: null, method: BodyCompositionMethod.VisualEstimate);

        Assert.Equal("mifflin_st_jeor", unknown.BmrSource);
        Assert.True(unknown.BasalMetabolicRateKcal > 0);
    }

    [Fact]
    public void Targets_declare_when_they_go_stale()
    {
        var target = TargetEngine.Derive(Baseline(), Request(), Today);

        Assert.Equal(Today.AddDays(28), target.RecalculateAfter);
    }
}
