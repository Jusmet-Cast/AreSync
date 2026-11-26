using FitCodex.Domain.Profiles;

namespace FitCodex.Domain.Targets;

/// <summary>
/// Lo que el usuario declara querer. Sale de la conversacion de onboarding,
/// no de un formulario con defaults: el objetivo y la prisa son decisiones
/// suyas, el resto lo deriva el motor.
/// </summary>
public sealed record ObjectiveRequest
{
    public required TrainingObjective Objective { get; init; }
    public required ActivityLevel ActivityLevel { get; init; }
    public Aggressiveness Aggressiveness { get; init; } = Aggressiveness.Moderate;

    /// <summary>Peso o grasa corporal a la que se quiere llegar, si la declaro.</summary>
    public decimal? TargetWeightKg { get; init; }
    public decimal? TargetBodFatPercent { get; init; }

    /// <summary>Plazo deseado. El motor dice si es alcanzable, no lo acepta sin mas.</summary>
    public int? DesiredWeeks { get; init; }
}

/// <summary>
/// Deriva los targets de UN usuario a partir de su punto de partida real.
///
/// Reglas heredadas del sistema agentico (System/Agentes/): proteina 1.8
/// g/kg como piso y 2.2-2.4 g/kg en recomposicion activa, grasa 25-30% de
/// las calorias, 7.500-10.000 pasos como rango activo, sueño objetivo >= 80,
/// y la alerta de NUTRISYNC cuando se pierde mas de 0.5 kg por semana.
///
/// Reglas que el sistema agentico NO tenia porque solo servia a un usuario, y
/// que agrega este motor: proteina referida a MASA MAGRA y no a peso total
/// (a 35% de grasa las dos cifras difieren tanto que la misma regla produce
/// prescripciones opuestas), techo de deficit como porcentaje del gasto en
/// vez de kcal absolutas, piso de grasa esencial por sexo, y limite de ritmo
/// semanal como porcentaje del peso corporal.
///
/// Las cifras de esta segunda categoria son estandares de la literatura de
/// nutricion deportiva, no indicaciones clinicas: estan marcadas para que un
/// profesional las valide antes de que la app se las recomiende a nadie.
/// </summary>
public static class TargetEngine
{
    /// <summary>
    /// Grasa corporal minima por sexo. Por debajo de esto no se prescribe
    /// deficit: deja de ser estetica y pasa a ser salud.
    /// Pendiente de validacion profesional.
    /// </summary>
    private const decimal MaleEssentialFatFloor = 8m;
    private const decimal FemaleEssentialFatFloor = 15m;

    /// <summary>
    /// El deficit nunca lleva la ingesta por debajo del metabolismo basal:
    /// comer menos de lo que el cuerpo gasta en reposo no acelera nada, lo
    /// que hace es canibalizar masa magra.
    /// </summary>
    private const decimal MinimumIntakeAsBmrMultiple = 1.0m;

    public static TargetSet Derive(BodyComposition baseline, ObjectiveRequest request, DateOnly today)
    {
        var constraints = new List<TargetConstraint>();

        if (!baseline.Method.IsMeasured())
        {
            constraints.Add(TargetConstraint.UnmeasuredBaseline);
        }

        var maintenance = Math.Round(
            baseline.BasalMetabolicRateKcal * request.ActivityLevel.Multiplier(), 0);

        var offset = EnergyOffset(baseline, request, maintenance, constraints);
        var targetKcal = maintenance + offset;

        // El piso metabolico se aplica despues de calcular el offset: si lo
        // recorta, el usuario tiene que enterarse de que su plan es menos
        // agresivo de lo que pidio, no descubrirlo por el numero final.
        var floor = baseline.BasalMetabolicRateKcal * MinimumIntakeAsBmrMultiple;
        if (targetKcal < floor)
        {
            targetKcal = Math.Round(floor, 0);
            offset = (int)(targetKcal - maintenance);
            constraints.Add(TargetConstraint.MetabolicFloor);
        }

        var protein = ProteinTarget(baseline, request.Objective);
        var fat = FatTarget(targetKcal);
        var carbs = CarbTarget(targetKcal, protein, fat);

        var weeklyChange = Math.Round(offset * 7m / 7700m, 3);

        if (request.DesiredWeeks is { } weeks && request.TargetWeightKg is { } goalWeight)
        {
            var requiredWeekly = (goalWeight - baseline.WeightKg) / weeks;

            if (Math.Abs(requiredWeekly) > Math.Abs(weeklyChange) * 1.05m)
            {
                constraints.Add(TargetConstraint.TimelineInfeasible);
            }
        }

        return new TargetSet
        {
            MaintenanceKcal = maintenance,
            TargetKcal = targetKcal,
            DailyEnergyOffsetKcal = offset,
            ProteinG = protein,
            FatG = fat,
            CarbsG = carbs,
            DailyStepGoal = StepGoal(request.ActivityLevel, request.Objective),
            SleepScoreGoal = 80,
            ExpectedWeeklyWeightChangeKg = weeklyChange,
            Confidence = baseline.Method.Confidence(),
            BaselineMethod = baseline.Method,
            Constraints = constraints,
            RecalculateAfter = today.AddDays(28)
        };
    }

    private static int EnergyOffset(
        BodyComposition baseline,
        ObjectiveRequest request,
        decimal maintenance,
        List<TargetConstraint> constraints)
    {
        if (request.Objective is TrainingObjective.Maintenance or TrainingObjective.Performance)
        {
            return 0;
        }

        if (request.Objective is TrainingObjective.MuscleGain)
        {
            // El superavit se mide en porcentaje del gasto y no en kcal fijas:
            // 300 kcal sobre 1.800 es otra cosa que sobre 3.200. Mas alla de
            // cierto punto lo que se gana es grasa, no musculo.
            var surplusPercent = request.Aggressiveness switch
            {
                Aggressiveness.Conservative => 0.05m,
                Aggressiveness.Moderate => 0.10m,
                _ => 0.15m
            };

            return (int)Math.Round(maintenance * surplusPercent, 0);
        }

        var floorForSex = baseline.Sex == BiologicalSex.Male
            ? MaleEssentialFatFloor
            : FemaleEssentialFatFloor;

        if (baseline.BodyFatPercent is { } bodyFat && bodyFat <= floorForSex)
        {
            // Ya esta en el piso: no se prescribe deficit aunque lo pida.
            constraints.Add(TargetConstraint.EssentialFatFloor);
            return 0;
        }

        var deficitPercent = request.Aggressiveness switch
        {
            Aggressiveness.Conservative => 0.10m,
            Aggressiveness.Moderate => 0.20m,
            _ => 0.25m
        };

        // Recomposicion es un deficit leve por definicion: un deficit grande
        // y ganar musculo a la vez no conviven.
        if (request.Objective == TrainingObjective.Recomposition)
        {
            deficitPercent = Math.Min(deficitPercent, 0.10m);
        }

        // Cuanta mas grasa de reserva hay, mas agresivo se tolera; cuanta
        // menos, mas se protege la masa magra.
        if (baseline.BodyFatPercent is { } bf)
        {
            var headroom = bf - floorForSex;
            if (headroom < 10m)
            {
                deficitPercent = Math.Min(deficitPercent, 0.15m);
            }
        }

        var offset = -(int)Math.Round(maintenance * deficitPercent, 0);

        // NUTRISYNC escala cuando se pierde mas de 0.5 kg/semana por riesgo
        // de perdida muscular. Expresado como tope de ritmo, eso es ~1% del
        // peso corporal por semana.
        var maxWeeklyLossKg = baseline.WeightKg * 0.01m;
        var maxDailyDeficit = -(maxWeeklyLossKg * 7700m / 7m);

        if (offset < maxDailyDeficit)
        {
            offset = (int)Math.Round(maxDailyDeficit, 0);
            constraints.Add(TargetConstraint.MaxWeeklyRate);
        }

        return offset;
    }

    /// <summary>
    /// Proteina referida a MASA MAGRA, no a peso corporal.
    ///
    /// Es la correccion mas importante para multi-usuario: "2 g/kg" sobre
    /// alguien de 120 kg con 40% de grasa da 240 g, una cifra que no tiene
    /// sustento fisiologico porque el tejido graso no demanda proteina. Sobre
    /// su masa magra (72 kg) da 144 g, que si es una prescripcion real.
    /// </summary>
    private static TargetRange ProteinTarget(BodyComposition baseline, TrainingObjective objective)
    {
        var leanMass = baseline.EstimatedLeanMassKg;

        var (minPerKg, maxPerKg) = objective switch
        {
            // En deficit la proteina sube: es lo que protege la masa magra
            // cuando la energia escasea.
            TrainingObjective.FatLoss => (2.2m, 2.6m),
            TrainingObjective.Recomposition => (2.2m, 2.8m),
            TrainingObjective.MuscleGain => (1.8m, 2.4m),
            TrainingObjective.Performance => (1.8m, 2.2m),
            _ => (1.6m, 2.0m)
        };

        return new TargetRange(
            Math.Round(leanMass * minPerKg, 0),
            Math.Round(leanMass * maxPerKg, 0));
    }

    /// <summary>Grasa: 25-30% de las calorias, como define NUTRISYNC.</summary>
    private static TargetRange FatTarget(decimal targetKcal) =>
        new(Math.Round(targetKcal * 0.25m / 9m, 0),
            Math.Round(targetKcal * 0.30m / 9m, 0));

    /// <summary>
    /// Los carbohidratos son el resto: proteina y grasa tienen piso
    /// fisiologico, los carbos son la palanca que absorbe el ajuste.
    /// </summary>
    private static TargetRange CarbTarget(decimal targetKcal, TargetRange protein, TargetRange fat)
    {
        var fromProtein = protein.Midpoint * 4m;
        var fromFat = fat.Midpoint * 9m;
        var remaining = Math.Max(targetKcal - fromProtein - fromFat, 0);

        return new TargetRange(
            Math.Round(remaining * 0.9m / 4m, 0),
            Math.Round(remaining * 1.1m / 4m, 0));
    }

    /// <summary>
    /// Pasos. PULSE marca 7.500-10.000 como rango activo y menos de 5.000
    /// como sedentario con impacto negativo en recomposicion. A quien hoy es
    /// sedentario no se le exige 10.000 el primer dia: se le pide el escalon
    /// siguiente, que es el que se sostiene.
    /// </summary>
    private static int StepGoal(ActivityLevel level, TrainingObjective objective)
    {
        var baseGoal = level switch
        {
            ActivityLevel.Sedentary => 6_000,
            ActivityLevel.LightlyActive => 8_000,
            ActivityLevel.ModeratelyActive => 10_000,
            _ => 12_000
        };

        return objective == TrainingObjective.FatLoss
            ? baseGoal + 1_000
            : baseGoal;
    }
}
