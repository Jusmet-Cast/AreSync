import '../entities/arc.dart';

/// Contrato de persistencia del Arc. No dice de donde viene el dato: hoy es
/// un mock en memoria, mañana es Drift local sincronizado contra `app/api`
/// (que a su vez espeja Routes of Arcs en Notion para quien siga operando
/// desde ahi). Ninguna pantalla importa la implementacion, solo esto.
abstract interface class ArcRepository {
  Future<Arc?> arcActivo();
  Future<List<Arc>> historial();
  Future<void> guardar(Arc arc);
}
