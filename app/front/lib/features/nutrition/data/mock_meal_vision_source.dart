import '../domain/ports/meal_vision_source.dart';

/// Devuelve siempre la misma estimacion de ejemplo. Sirve para construir la
/// pantalla de "sacarle foto a la comida" sin pagar ni configurar un
/// proveedor de vision todavia. El reemplazo real vive en `app/api`: la API
/// key de Gemini/DeepSeek no se empaqueta en el cliente.
class MockMealVisionSource implements MealVisionSource {
  const MockMealVisionSource();

  @override
  Future<MacroEstimate> estimarDesdeFoto(List<int> bytesDeImagen) async {
    return const MacroEstimate(
      componentes: <ComponenteDetectado>[
        ComponenteDetectado(
          nombre: 'Pechuga de pollo (~150 g)',
          proteinaG: 38,
          carbohidratosG: 0,
          grasaG: 4,
          calorias: 195,
        ),
        ComponenteDetectado(
          nombre: 'Arroz blanco (~1 taza)',
          proteinaG: 4,
          carbohidratosG: 45,
          grasaG: 0.5,
          calorias: 205,
        ),
        ComponenteDetectado(
          nombre: 'Vegetales salteados',
          proteinaG: 2,
          carbohidratosG: 8,
          grasaG: 3,
          calorias: 65,
        ),
      ],
      confianza: ConfianzaEstimacion.media,
      notaMetodo: 'Porciones estimadas visualmente, sin referencia de tamaño '
          'en la foto.',
    );
  }
}
