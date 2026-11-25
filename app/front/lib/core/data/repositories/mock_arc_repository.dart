import '../../domain/entities/arc.dart';
import '../../domain/ports/arc_repository.dart';

/// Implementacion en memoria. Sirve para construir y probar toda la UI sin
/// esperar al backend — y sirve de documentacion viva de que forma tiene que
/// respetar cualquier implementacion real que la reemplace.
///
/// El seed es generico a proposito (no son los datos de Justyn): cualquiera
/// que clone este repo y corra la app por primera vez tiene que ver un Arc
/// de ejemplo razonable, no la composicion corporal de otra persona.
class MockArcRepository implements ArcRepository {
  MockArcRepository() : _arcs = <Arc>[_arcDeEjemplo];

  final List<Arc> _arcs;

  static final Arc _arcDeEjemplo = Arc(
    id: 'arc-ejemplo-1',
    nombre: 'Mi primer Arc',
    tipo: ArcType.hybrid,
    estado: ArcStatus.activo,
    fechaInicio: DateTime.now().subtract(const Duration(days: 28)),
    fechaFin: DateTime.now().add(const Duration(days: 84)),
    descripcionBreve:
        'Ciclo de recomposicion: bajar grasa conservando masa magra y subir '
        'capacidad aerobica, con el sueño como primera palanca.',
    goals: const ArcGoals(
      pesoObjetivoKg: 78,
      grasaObjetivoPorciento: 18,
      masaLibreDeGrasaObjetivoKg: 62,
      proteinaMinG: 150,
      proteinaMaxG: 170,
      pasosObjetivo: 8000,
      sleepScoreObjetivo: 80,
      vo2MaxObjetivo: 45,
    ),
    pesoInicialKg: 85,
    deficitFaseActualKcal: -400,
    progresoPorciento: 25,
    scorePromedioAdherencia: 78,
  );

  @override
  Future<Arc?> arcActivo() async {
    for (final Arc arc in _arcs) {
      if (arc.estaActivo) return arc;
    }
    return null;
  }

  @override
  Future<List<Arc>> historial() async => List<Arc>.unmodifiable(_arcs);

  @override
  Future<void> guardar(Arc arc) async {
    final int indice = _arcs.indexWhere((Arc a) => a.id == arc.id);
    if (indice == -1) {
      _arcs.add(arc);
    } else {
      _arcs[indice] = arc;
    }
  }
}
