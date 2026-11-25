/// Que tan segura esta la estimacion. Igual escala que el checklist de
/// NUTRISYNC (Alta/Media/Baja): un macro estimado por foto nunca se muestra
/// como si fuera un dato medido, para que el usuario sepa cuanto confiar.
enum ConfianzaEstimacion { alta, media, baja }

/// Un componente individual detectado en la foto (ej. "pechuga de pollo,
/// ~150g") con su aporte. La suma de todos da el total — mostrar el
/// desglose, no solo el total, es lo que permite corregir un componente mal
/// leido sin descartar toda la estimacion.
class ComponenteDetectado {
  const ComponenteDetectado({
    required this.nombre,
    required this.proteinaG,
    required this.carbohidratosG,
    required this.grasaG,
    required this.calorias,
  });

  final String nombre;
  final double proteinaG;
  final double carbohidratosG;
  final double grasaG;
  final double calorias;
}

/// Resultado de estimar una comida a partir de una foto.
class MacroEstimate {
  const MacroEstimate({
    required this.componentes,
    required this.confianza,
    this.notaMetodo,
  });

  final List<ComponenteDetectado> componentes;
  final ConfianzaEstimacion confianza;

  /// Por que esta estimacion tiene esta confianza (ej. "porcion estimada
  /// visualmente, sin referencia de tamaño"). Espejo del campo `Notas` que
  /// NUTRISYNC llena en FoodLog explicando el metodo de cada componente.
  final String? notaMetodo;

  double get proteinaTotalG =>
      componentes.fold(0, (double s, ComponenteDetectado c) => s + c.proteinaG);
  double get carbohidratosTotalG =>
      componentes.fold(0, (double s, ComponenteDetectado c) => s + c.carbohidratosG);
  double get grasaTotalG =>
      componentes.fold(0, (double s, ComponenteDetectado c) => s + c.grasaG);
  double get caloriasTotal =>
      componentes.fold(0, (double s, ComponenteDetectado c) => s + c.calorias);
}

/// Contrato para estimar macros a partir de una foto de comida.
///
/// Deliberadamente tercerizado: FitCodex no entrena un modelo de vision
/// propio, delega a un proveedor externo (Gemini, DeepSeek u otro que se
/// evalue mas adelante). Esta interfaz es lo que vuelve ese proveedor
/// intercambiable — igual que `TelemetrySource` vuelve intercambiable el
/// wearable. Hoy la unica implementacion es un mock; el adaptador real se
/// monta en `app/api`, nunca pegado directo desde el cliente (la API key del
/// proveedor de vision no puede viajar dentro del APK).
abstract interface class MealVisionSource {
  Future<MacroEstimate> estimarDesdeFoto(List<int> bytesDeImagen);
}
