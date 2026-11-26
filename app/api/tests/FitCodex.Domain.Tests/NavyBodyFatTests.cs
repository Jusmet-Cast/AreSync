using FitCodex.Domain.Profiles;

namespace FitCodex.Domain.Tests;

public class NavyBodyFatTests
{
    [Fact]
    public void Male_formula_matches_the_documented_measurement()
    {
        // Lecturas reales del sistema: cuello 37.1, abdomen ~81.9, 175 cm.
        var result = NavyBodyFat.Estimate(
            BiologicalSex.Male, heightCm: 175, neckCm: 37.1m, waistCm: 81.9m);

        Assert.InRange(result, 15m, 20m);
    }

    [Fact]
    public void Female_formula_requires_the_hip_measurement()
    {
        Assert.Throws<ArgumentException>(() =>
            NavyBodyFat.Estimate(BiologicalSex.Female, 165, 32, 75));
    }

    [Fact]
    public void Female_formula_works_with_the_hip_measurement()
    {
        var result = NavyBodyFat.Estimate(
            BiologicalSex.Female, heightCm: 165, neckCm: 32, waistCm: 75, hipCm: 97);

        Assert.InRange(result, 20m, 35m);
    }

    [Fact]
    public void A_waist_smaller_than_the_neck_is_rejected_as_a_bad_measurement()
    {
        // La formula devolveria un logaritmo de un negativo. Es mas util
        // decir "mediste mal" que devolver NaN.
        Assert.Throws<ArgumentException>(() =>
            NavyBodyFat.Estimate(BiologicalSex.Male, 175, neckCm: 40, waistCm: 38));
    }

    [Fact]
    public void A_bigger_waist_yields_a_higher_estimate()
    {
        var slim = NavyBodyFat.Estimate(BiologicalSex.Male, 175, 37, 80);
        var wider = NavyBodyFat.Estimate(BiologicalSex.Male, 175, 37, 90);

        Assert.True(wider > slim);
    }

    [Fact]
    public void One_waist_centimetre_moves_the_estimate_about_eight_tenths_of_a_point()
    {
        // Es la sensibilidad documentada, y sirve para distinguir una mejora
        // real del ruido de la cinta metrica.
        var at80 = NavyBodyFat.Estimate(BiologicalSex.Male, 175, 37, 80);
        var at81 = NavyBodyFat.Estimate(BiologicalSex.Male, 175, 37, 81);

        Assert.InRange(at81 - at80, 0.5m, 1.1m);
    }

    [Fact]
    public void AverageReadings_rejects_an_empty_series() =>
        Assert.Throws<ArgumentException>(() => NavyBodyFat.AverageReadings([]));

    [Fact]
    public void AverageReadings_averages_the_protocol_triplicate()
    {
        var average = NavyBodyFat.AverageReadings([37.00m, 37.20m, 37.10m]);

        Assert.Equal(37.10m, average);
    }
}
