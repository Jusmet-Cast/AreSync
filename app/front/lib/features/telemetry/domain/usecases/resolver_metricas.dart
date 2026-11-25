import '../../../../core/domain/entities/metric.dart';
import '../../../../core/domain/ports/telemetry_source.dart';

/// Resultado de consultar todas las fuentes por una metrica.
class LecturaResuelta {
  const LecturaResuelta({required this.tipo, this.ganadora, this.descartadas = const <Metric>[]});

  final MetricType tipo;

  /// La lectura elegida. `null` significa que ninguna fuente publica este tipo
  /// — el caso de HRV con una Xiaomi global. La UI lo muestra como hueco
  /// declarado, no como cero.
  final Metric? ganadora;

  /// Las que perdieron. Se guardan para poder explicar la decision.
  final List<Metric> descartadas;

  bool get hayDato => ganadora != null;
}

/// Ante duplicados de la misma metrica, gana la fuente de mayor peso.
///
/// El caso real: el telefono cuenta pasos y la banda tambien. Sin esta regla
/// se suman y el usuario camina el doble que en la vida real.
class ResolverMetricas {
  const ResolverMetricas(this._fuentes);

  final List<TelemetrySource> _fuentes;

  Future<LecturaResuelta> resolver({
    required MetricType tipo,
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final List<Metric> lecturas = <Metric>[];

    for (final TelemetrySource fuente in _fuentes) {
      if (!await fuente.disponible()) {
        continue;
      }
      lecturas.addAll(await fuente.leer(tipo: tipo, desde: desde, hasta: hasta));
    }

    if (lecturas.isEmpty) {
      return LecturaResuelta(tipo: tipo);
    }

    lecturas.sort((Metric a, Metric b) {
      final int porPeso = b.peso.compareTo(a.peso);
      // A igual peso gana la mas reciente.
      return porPeso != 0 ? porPeso : b.recordedAt.compareTo(a.recordedAt);
    });

    return LecturaResuelta(
      tipo: tipo,
      ganadora: lecturas.first,
      descartadas: lecturas.sublist(1),
    );
  }

  /// Que metricas quedan sin cubrir con las fuentes conectadas hoy.
  /// Alimenta la seccion "Cobertura de metricas" de la pantalla Fuentes.
  Future<Set<MetricType>> huecos() async {
    final Set<MetricType> cubiertas = <MetricType>{};

    for (final TelemetrySource fuente in _fuentes) {
      if (await fuente.disponible()) {
        cubiertas.addAll(await fuente.metricasDisponibles());
      }
    }

    return MetricType.values.toSet().difference(cubiertas);
  }
}
