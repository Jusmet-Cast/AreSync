namespace FitCodex.Domain.Energy;

/// <summary>
/// Un pesaje crudo de balanza.
/// </summary>
public readonly record struct WeightObservation(DateOnly Date, decimal Kg);

/// <summary>
/// Tendencia de peso suavizada.
///
/// El peso de balanza NO es el peso del cuerpo: agua, glucogeno, sodio y lo
/// que hay en el intestino mueven uno o dos kilos de un dia al otro, que es
/// mas que la señal que se intenta medir en una semana entera. Comparar dos
/// pesajes sueltos es leer ruido y llamarlo progreso.
///
/// Se usa una media movil exponencial: cada dia pesa un poco y los recientes
/// pesan mas, sin necesidad de guardar toda la serie ni de descartar dias
/// sueltos a mano.
/// </summary>
public sealed class WeightTrend
{
    /// <summary>
    /// Cuanto pesa cada pesaje nuevo contra la historia acumulada. 1/7 deja
    /// una inercia de alrededor de una semana: suficiente para aplanar el
    /// rebote de una comida con sal, no tanto como para tardar un mes en
    /// reflejar un cambio real.
    /// </summary>
    public const decimal DefaultSmoothing = 1m / 7m;

    private readonly List<(DateOnly Date, decimal Value)> _points = [];

    private WeightTrend()
    {
    }

    public IReadOnlyList<(DateOnly Date, decimal Value)> Points => _points;

    public bool IsEmpty => _points.Count == 0;

    public decimal? First => _points.Count > 0 ? _points[0].Value : null;

    public decimal? Latest => _points.Count > 0 ? _points[^1].Value : null;

    public int DaySpan => _points.Count < 2
        ? 0
        : _points[^1].Date.DayNumber - _points[0].Date.DayNumber;

    /// <summary>
    /// Cambio total de la tendencia en el periodo observado, en kg.
    /// </summary>
    public decimal? Change => _points.Count < 2 ? null : _points[^1].Value - _points[0].Value;

    public static WeightTrend From(
        IEnumerable<WeightObservation> observations,
        decimal? smoothing = null)
    {
        var alpha = smoothing ?? DefaultSmoothing;

        if (alpha is <= 0 or > 1)
        {
            throw new ArgumentOutOfRangeException(nameof(smoothing),
                "El factor de suavizado tiene que estar entre 0 y 1.");
        }

        var trend = new WeightTrend();

        // Varios pesajes el mismo dia (antes y despues de desayunar, por
        // ejemplo) se promedian: ninguno de los dos es mas verdadero.
        var daily = observations
            .GroupBy(o => o.Date)
            .Select(g => new WeightObservation(g.Key, g.Average(o => o.Kg)))
            .OrderBy(o => o.Date)
            .ToList();

        decimal? current = null;

        foreach (var observation in daily)
        {
            current = current is null
                ? observation.Kg
                : current.Value + alpha * (observation.Kg - current.Value);

            trend._points.Add((observation.Date, Math.Round(current.Value, 3)));
        }

        return trend;
    }

    /// <summary>
    /// Cambio semanal de la tendencia. Es lo que se le muestra al usuario en
    /// vez del delta entre dos pesajes: la pregunta real es hacia donde va,
    /// no cuanto marcó hoy.
    /// </summary>
    public decimal? WeeklyChangeKg
    {
        get
        {
            if (Change is not { } change || DaySpan == 0)
            {
                return null;
            }

            return Math.Round(change / DaySpan * 7m, 3);
        }
    }
}
