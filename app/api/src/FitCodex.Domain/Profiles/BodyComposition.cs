namespace FitCodex.Domain.Profiles;

/// <summary>
/// Sexo biologico. No es un campo de identidad: entra al dominio porque las
/// formulas lo exigen (Navy usa cadera solo en mujeres, las bandas de grasa
/// corporal y de VO2max difieren, y la masa magra esperada tambien).
/// Separarlo de como la persona se identifica es responsabilidad de la capa
/// de perfil, no de este calculo.
/// </summary>
public enum BiologicalSex
{
    Male,
    Female
}

/// <summary>
/// Como se obtuvo la medicion. Determina cuanto se puede confiar en el punto
/// de partida y, por lo tanto, que tan agresivo puede ser el objetivo que el
/// sistema derive de el.
/// </summary>
public enum BodyCompositionMethod
{
    Dxa,
    Navy,
    Bioimpedance,
    Caliper,
    VisualEstimate
}

public static class BodyCompositionMethods
{
    /// <summary>
    /// Confianza 0..1 del metodo. DXA es la referencia; Navy arrastra ±3-4
    /// puntos contra DXA; un estimado visual no sostiene ninguna prescripcion
    /// agresiva y por eso puntua tan bajo.
    /// </summary>
    public static decimal Confidence(this BodyCompositionMethod method) => method switch
    {
        BodyCompositionMethod.Dxa => 1.0m,
        BodyCompositionMethod.Navy => 0.7m,
        BodyCompositionMethod.Bioimpedance => 0.6m,
        BodyCompositionMethod.Caliper => 0.65m,
        BodyCompositionMethod.VisualEstimate => 0.3m,
        _ => 0.3m
    };

    /// <summary>
    /// Si el metodo mide la grasa corporal o solo la estima a ojo. Un
    /// objetivo de composicion corporal no se puede fijar sobre un estimado
    /// visual: se puede empezar igual, pero el sistema tiene que decir que
    /// esta trabajando a ciegas.
    /// </summary>
    public static bool IsMeasured(this BodyCompositionMethod method) =>
        method != BodyCompositionMethod.VisualEstimate;
}

/// <summary>
/// El punto de partida del usuario. Todo target que el sistema derive se
/// calcula contra esto — sin una composicion corporal no hay forma honesta de
/// fijar un deficit ni un piso de proteina.
/// </summary>
public sealed record BodyComposition
{
    public BodyComposition(
        decimal weightKg,
        decimal heightCm,
        BiologicalSex sex,
        int age,
        BodyCompositionMethod method,
        DateOnly measuredOn,
        decimal? bodyFatPercent = null,
        decimal? measuredRmrKcal = null)
    {
        if (weightKg <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(weightKg));
        }

        if (heightCm <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(heightCm));
        }

        if (bodyFatPercent is < 0 or > 75)
        {
            throw new ArgumentOutOfRangeException(nameof(bodyFatPercent),
                "Un porcentaje de grasa fuera de 0-75 es un error de carga, no una medicion.");
        }

        WeightKg = weightKg;
        HeightCm = heightCm;
        Sex = sex;
        Age = age;
        Method = method;
        MeasuredOn = measuredOn;
        BodyFatPercent = bodyFatPercent;
        MeasuredRmrKcal = measuredRmrKcal;
    }

    public decimal WeightKg { get; }
    public decimal HeightCm { get; }
    public BiologicalSex Sex { get; }
    public int Age { get; }
    public BodyCompositionMethod Method { get; }
    public DateOnly MeasuredOn { get; }
    public decimal? BodyFatPercent { get; }

    /// <summary>
    /// TMR medida por el equipo (DXA la reporta). Cuando existe, gana sobre
    /// cualquier formula: una ecuacion generica estima la media de una
    /// poblacion, no el metabolismo de esta persona.
    /// </summary>
    public decimal? MeasuredRmrKcal { get; }

    public decimal? LeanMassKg =>
        BodyFatPercent is { } bf ? Math.Round(WeightKg * (1 - bf / 100m), 2) : null;

    public decimal? FatMassKg =>
        BodyFatPercent is { } bf ? Math.Round(WeightKg * (bf / 100m), 2) : null;

    public decimal Bmi => Math.Round(WeightKg / (HeightCm / 100m * (HeightCm / 100m)), 2);

    /// <summary>
    /// Masa magra, o una estimacion conservadora cuando no hay grasa medida.
    /// El fallback usa el extremo alto del rango de grasa tipico por sexo:
    /// subestimar la masa magra baja el piso de proteina y el deficit, que es
    /// el lado seguro para equivocarse.
    /// </summary>
    public decimal EstimatedLeanMassKg =>
        LeanMassKg ?? WeightKg * (Sex == BiologicalSex.Male ? 0.72m : 0.65m);

    /// <summary>
    /// Metabolismo basal. Usa la TMR medida si existe; si no, Mifflin-St Jeor
    /// cuando no hay grasa corporal, y Katch-McArdle cuando si la hay —
    /// Katch parte de la masa magra, asi que es mas preciso en cualquiera que
    /// se aleje de la composicion promedio (que es casi todo el mundo que usa
    /// una app de esto).
    /// </summary>
    public decimal BasalMetabolicRateKcal
    {
        get
        {
            if (MeasuredRmrKcal is { } measured)
            {
                return measured;
            }

            if (LeanMassKg is { } lean)
            {
                return Math.Round(370 + 21.6m * lean, 0);
            }

            var mifflin = 10m * WeightKg + 6.25m * HeightCm - 5m * Age;
            return Math.Round(Sex == BiologicalSex.Male ? mifflin + 5 : mifflin - 161, 0);
        }
    }

    /// <summary>
    /// De donde salio el metabolismo basal que se esta usando. La app lo
    /// muestra: un numero medido y uno estimado no merecen la misma confianza
    /// y el usuario tiene derecho a saber cual le tocó.
    /// </summary>
    public string BmrSource =>
        MeasuredRmrKcal is not null ? "measured"
        : LeanMassKg is not null ? "katch_mcardle"
        : "mifflin_st_jeor";
}
