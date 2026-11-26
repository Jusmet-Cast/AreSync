using FitCodex.Domain.Adherence;

namespace FitCodex.Domain.Tests;

public class RecoveryIndexTests
{
    [Fact]
    public void Calculate_sums_base_and_the_four_components()
    {
        // 50 base + 20 (rhr < 50) + 20 (sleep >= 80) + 20 (load low) + 10 (vitality >= 50)
        var score = RecoveryIndex.Calculate(new RecoveryInputs(
            RestingHeartRateBpm: 48,
            SleepScore: 85,
            WeeklyTrainingLoad: 250,
            VitalityScore: 60));

        Assert.Equal(100, score);
    }

    [Fact]
    public void Calculate_never_exceeds_one_hundred()
    {
        var score = RecoveryIndex.Calculate(new RecoveryInputs(40, 100, 0, 100));

        Assert.InRange(score, 0, 100);
    }

    [Fact]
    public void Calculate_floors_at_the_base_when_every_component_scores_zero()
    {
        var score = RecoveryIndex.Calculate(new RecoveryInputs(
            RestingHeartRateBpm: 72,
            SleepScore: 55,
            WeeklyTrainingLoad: 700,
            VitalityScore: 10));

        Assert.Equal(50, score);
    }

    [Fact]
    public void Calculate_interpolates_the_gap_left_undefined_by_the_protocol()
    {
        // 60-65 bpm no estaba definido en el protocolo original. Tiene que
        // caer entre el tramo de abajo (+10) y el de arriba (0), no en cero.
        var middle = RecoveryIndex.Calculate(new RecoveryInputs(63, 0, 700, 0));
        var worse = RecoveryIndex.Calculate(new RecoveryInputs(70, 0, 700, 0));
        var better = RecoveryIndex.Calculate(new RecoveryInputs(58, 0, 700, 0));

        Assert.True(middle > worse);
        Assert.True(middle < better);
    }

    [Theory]
    [InlineData(85, SeverityBand.Green)]
    [InlineData(70, SeverityBand.Yellow)]
    [InlineData(45, SeverityBand.Orange)]
    [InlineData(30, SeverityBand.Red)]
    public void BandFor_uses_the_shared_severity_scale(int score, SeverityBand expected) =>
        Assert.Equal(expected, RecoveryIndex.BandFor(score));

    [Fact]
    public void Adherence_and_recovery_share_the_same_banding()
    {
        // Que "naranja" signifique lo mismo en los dos indices es lo que
        // permite mostrarlos juntos sin explicar dos escalas.
        Assert.Equal(RecoveryIndex.BandFor(45), AdherenceIndex.BandFor(45m));
    }

    [Fact]
    public void AdherenceIndex_averages_the_four_pillars_evenly()
    {
        var total = AdherenceIndex.Calculate(new AdherenceInputs(85, 72, 90, 70));

        Assert.Equal(79.25m, total);
    }
}
