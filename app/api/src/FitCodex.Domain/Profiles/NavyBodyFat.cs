namespace FitCodex.Domain.Profiles;

/// <summary>
/// Metodo Navy para estimar grasa corporal a partir de circunferencias.
///
/// Es el camino de entrada realista: una cinta metrica la tiene cualquiera,
/// un DXA no. Pero arrastra ±3-4 puntos de error contra DXA, con un sesgo
/// individual constante e impredecible — por eso un valor Navy se compara
/// contra otro Navy, nunca contra un DXA. El sistema guarda el metodo junto
/// al resultado justamente para poder impedir esa comparacion.
/// </summary>
public static class NavyBodyFat
{
    /// <summary>
    /// Sensibilidad aproximada: cada centimetro de cintura mueve el
    /// resultado cerca de 0.8 puntos de grasa. Sirve para decirle al usuario
    /// cuanto de una variacion es señal y cuanto es ruido de medicion.
    /// </summary>
    public const decimal PercentPerWaistCm = 0.8m;

    /// <summary>
    /// <paramref name="hipCm"/> solo lo usa la formula femenina; en hombres
    /// se ignora. Lanza si falta en una mujer en vez de asumir un valor:
    /// adivinarlo produce un numero que parece medido y no lo es.
    /// </summary>
    public static decimal Estimate(
        BiologicalSex sex,
        decimal heightCm,
        decimal neckCm,
        decimal waistCm,
        decimal? hipCm = null)
    {
        if (heightCm <= 0 || neckCm <= 0 || waistCm <= 0)
        {
            throw new ArgumentException("Las circunferencias y la estatura tienen que ser positivas.");
        }

        if (sex == BiologicalSex.Female && hipCm is null)
        {
            throw new ArgumentException(
                "La formula Navy para mujeres necesita la circunferencia de cadera.", nameof(hipCm));
        }

        var height = (double)heightCm;
        var neck = (double)neckCm;
        var waist = (double)waistCm;

        double result;

        if (sex == BiologicalSex.Male)
        {
            if (waist <= neck)
            {
                throw new ArgumentException(
                    "La cintura tiene que superar al cuello: si no, la medicion esta mal tomada.");
            }

            result = 495d / (1.0324d
                           - 0.19077d * Math.Log10(waist - neck)
                           + 0.15456d * Math.Log10(height)) - 450d;
        }
        else
        {
            var hip = (double)hipCm!.Value;

            if (waist + hip <= neck)
            {
                throw new ArgumentException(
                    "Cintura mas cadera tiene que superar al cuello: si no, la medicion esta mal tomada.");
            }

            result = 495d / (1.29579d
                           - 0.35004d * Math.Log10(waist + hip - neck)
                           + 0.22100d * Math.Log10(height)) - 450d;
        }

        return Math.Round((decimal)result, 2);
    }

    /// <summary>
    /// Promedia varias lecturas del mismo sitio. El protocolo real toma tres
    /// por sitio porque una sola lectura de cinta tiene mas ruido que la
    /// diferencia que se intenta detectar entre semanas.
    /// </summary>
    public static decimal AverageReadings(IReadOnlyCollection<decimal> readings)
    {
        if (readings.Count == 0)
        {
            throw new ArgumentException("Hace falta al menos una lectura.", nameof(readings));
        }

        return Math.Round(readings.Average(), 2);
    }
}
