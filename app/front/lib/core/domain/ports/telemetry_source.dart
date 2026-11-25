import '../entities/metric.dart';

/// Contrato que cumple toda fuente de telemetria.
///
/// Esta es la pieza que vuelve a FitCodex agnostico del wearable: la app
/// depende de esta interfaz, nunca de Health Connect ni de Apple Health
/// directamente. Sumar una fuente nueva es implementar esto una vez; ninguna
/// pantalla se entera.
///
/// Nota de Clean Architecture: este archivo no importa `package:flutter`.
/// El dominio no conoce el framework de UI, por eso el rango va como dos
/// DateTime y no como DateTimeRange de Material.
abstract interface class TelemetrySource {
  /// Que fuente es, para poder etiquetar cada dato con su procedencia.
  MetricSource get id;

  /// Que metricas entrega REALMENTE esta fuente en este dispositivo.
  ///
  /// No es la lista de lo que el SDK soporta en teoria: es lo que el wearable
  /// del usuario esta escribiendo. De aca sale el hueco de HRV que la pantalla
  /// de Telemetria muestra sin disimular.
  Future<Set<MetricType>> metricasDisponibles();

  /// La plataforma tiene la fuente instalada y utilizable.
  Future<bool> disponible();

  /// Pide permiso al usuario. Devuelve lo que efectivamente concedio, que
  /// puede ser menos de lo pedido.
  Future<Set<MetricType>> solicitarPermisos(Set<MetricType> tipos);

  /// Lee un rango. Devuelve lista vacia si la fuente no publica ese tipo:
  /// no lanza. Una metrica ausente es un estado normal, no un error.
  Future<List<Metric>> leer({
    required MetricType tipo,
    required DateTime desde,
    required DateTime hasta,
  });
}
