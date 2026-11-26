namespace FitCodex.Domain.Energy;

/// <summary>
/// Lo que se sabe de un dia: cuanto peso y cuanto comio. Cualquiera de los
/// dos puede faltar — se pesa sin haber registrado la comida, y se come sin
/// haberse pesado.
/// </summary>
public readonly record struct DailyEnergyRecord(DateOnly Date, decimal? WeightKg, decimal? IntakeKcal);

/// <summary>
/// Estima el gasto energetico real a partir de la evidencia del propio
/// usuario en vez de una ecuacion de poblacion.
///
/// El razonamiento es una identidad, no un modelo: la energia que entra y no
/// se gasta se almacena. Si durante tres semanas comio 2.400 kcal por dia y
/// su tendencia de peso bajo medio kilo por semana, gastaba alrededor de
/// 2.950 — sin importar lo que diga ninguna formula sobre su estatura, su
/// edad o su "nivel de actividad".
///
/// Esto es lo que vuelve al sistema honesto con alguien cuyo metabolismo no
/// se parece al promedio: el adaptado termal tras años de dieta, el que tiene
/// hipotiroidismo, o simplemente el que se mueve mucho mas de lo que cree.
/// </summary>
public static class AdaptiveTdee
{
    /// <summary>
    /// Energia por kilo de masa corporal ganada o perdida. 7.700 kcal/kg es
    /// la cifra clasica para tejido graso.
    ///
    /// Es una aproximacion y conviene saber por que: el tejido que se pierde
    /// en un deficit es mezcla de grasa, musculo y glucogeno con su agua, y
    /// esa mezcla no es constante. Las primeras dos semanas de cualquier
    /// cambio de dieta estan dominadas por glucogeno y agua, que cuestan
    /// mucho menos energia por kilo — por eso el estimador exige una ventana
    /// minima antes de tomarse en serio.
    /// </summary>
    public const decimal KcalPerKg = 7700m;

    /// <summary>
    /// Menos de dos semanas no alcanza. El ruido de agua y glucogeno de una
    /// sola semana puede inventar o borrar un deficit entero.
    /// </summary>
    public const int MinimumDays = 14;

    /// <summary>
    /// Ventana donde ya se confia enteramente en la observacion. Entre el
    /// minimo y esto, el resultado se mezcla con la formula.
    /// </summary>
    public const int FullConfidenceDays = 28;

    /// <summary>
    /// Por debajo de esta proporcion de dias registrados, lo que falta pesa
    /// mas que lo que hay.
    /// </summary>
    public const decimal MinimumIntakeCoverage = 0.70m;

    /// <summary>
    /// <paramref name="formulaTdeeKcal"/> es el punto de partida: lo que
    /// dicta el multiplicador de actividad mientras no haya evidencia propia.
    /// <paramref name="basalMetabolicRateKcal"/> se usa solo como control de
    /// plausibilidad del resultado.
    /// </summary>
    public static TdeeEstimate Estimate(
        IReadOnlyCollection<DailyEnergyRecord> records,
        decimal formulaTdeeKcal,
        decimal basalMetabolicRateKcal)
    {
        var warnings = new List<TdeeWarning>();

        var weights = records
            .Where(r => r.WeightKg is not null)
            .Select(r => new WeightObservation(r.Date, r.WeightKg!.Value))
            .ToList();

        var intakeDays = records.Where(r => r.IntakeKcal is not null).ToList();

        var trend = WeightTrend.From(weights);
        var daySpan = trend.DaySpan;

        // Cobertura contra el periodo real observado, no contra los dias que
        // el usuario eligio registrar: registrar solo los dias buenos es
        // exactamente el sesgo que esto tiene que detectar.
        var totalDays = daySpan + 1;
        var coverage = totalDays > 0
            ? Math.Round((decimal)intakeDays.Count / totalDays, 3)
            : 0m;

        if (daySpan < MinimumDays || weights.Count < 2)
        {
            warnings.Add(TdeeWarning.InsufficientData);

            return new TdeeEstimate
            {
                Kcal = Math.Round(formulaTdeeKcal, 0),
                Source = TdeeSource.Formula,
                Confidence = 0.2m,
                DaysOfData = daySpan,
                IntakeCoverage = coverage,
                ObservedWeeklyChangeKg = trend.WeeklyChangeKg,
                Warnings = warnings
            };
        }

        if (coverage < MinimumIntakeCoverage)
        {
            warnings.Add(TdeeWarning.SparseIntakeLogging);
        }

        if (HasHighVariance(weights, trend))
        {
            warnings.Add(TdeeWarning.HighWeightVariance);
        }

        var meanIntake = intakeDays.Average(r => r.IntakeKcal!.Value);
        var trendChangeKg = trend.Change ?? 0m;

        // La identidad: lo que no se almaceno, se gasto.
        var observed = meanIntake - trendChangeKg * KcalPerKg / daySpan;

        if (observed < basalMetabolicRateKcal)
        {
            // Un gasto por debajo del basal es fisiologicamente muy raro y
            // casi siempre significa comida sin registrar. Se avisa en vez de
            // devolver un numero que llevaria a prescribir una dieta de
            // hambre sobre un error de registro.
            warnings.Add(TdeeWarning.ImplausiblyLow);
        }

        var weight = ObservationWeight(daySpan, coverage, warnings);
        var blended = observed * weight + formulaTdeeKcal * (1 - weight);

        return new TdeeEstimate
        {
            Kcal = Math.Round(blended, 0),
            Source = weight >= 0.99m ? TdeeSource.Observed
                   : weight <= 0.01m ? TdeeSource.Formula
                   : TdeeSource.Blended,
            Confidence = Math.Round(weight, 2),
            DaysOfData = daySpan,
            IntakeCoverage = coverage,
            ObservedWeeklyChangeKg = trend.WeeklyChangeKg,
            Warnings = warnings
        };
    }

    /// <summary>
    /// Cuanto pesa la observacion contra la formula. Sube con los dias de
    /// datos y baja con los problemas detectados: el sistema se va soltando
    /// de la tabla a medida que conoce a la persona, y vuelve a agarrarse de
    /// ella cuando los datos dejan de ser confiables.
    /// </summary>
    private static decimal ObservationWeight(int daySpan, decimal coverage, List<TdeeWarning> warnings)
    {
        var byDays = Math.Clamp(
            (decimal)(daySpan - MinimumDays) / (FullConfidenceDays - MinimumDays),
            0m, 1m);

        var weight = byDays;

        if (warnings.Contains(TdeeWarning.SparseIntakeLogging))
        {
            weight *= coverage;
        }

        if (warnings.Contains(TdeeWarning.HighWeightVariance))
        {
            weight *= 0.5m;
        }

        if (warnings.Contains(TdeeWarning.ImplausiblyLow))
        {
            // No se descarta del todo: se reporta, pero no se le deja
            // arrastrar la prescripcion.
            weight *= 0.25m;
        }

        return Math.Clamp(weight, 0m, 1m);
    }

    /// <summary>
    /// Mide cuanto se despegan los pesajes crudos de su propia tendencia. Un
    /// cuerpo que oscila dos kilos por dia no permite leer un cambio de medio
    /// kilo por semana.
    /// </summary>
    private static bool HasHighVariance(
        IReadOnlyList<WeightObservation> weights,
        WeightTrend trend)
    {
        if (weights.Count < 3 || trend.Points.Count != weights.Count)
        {
            return false;
        }

        var deviations = weights
            .Select((w, i) => Math.Abs(w.Kg - trend.Points[i].Value))
            .ToList();

        var meanDeviation = deviations.Average();
        var meanWeight = weights.Average(w => w.Kg);

        // Mas de 1.5% del peso corporal de desvio medio es demasiado ruido
        // para leer la señal semanal.
        return meanDeviation > meanWeight * 0.015m;
    }
}
