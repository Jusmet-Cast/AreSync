import '../domain/entities/adventure.dart';
import '../domain/ports/adventure_repository.dart';

class MockAdventureRepository implements AdventureRepository {
  MockAdventureRepository() : _aventuras = <Adventure>[..._seed];

  final List<Adventure> _aventuras;

  static final List<Adventure> _seed = <Adventure>[
    Adventure(
      id: 'adv-1',
      destino: 'Sendero del Mirador',
      tipos: const <TipoActividad>{TipoActividad.hiking},
      estado: EstadoAventura.proximoDesafio,
      dificultad: Dificultad.moderada,
      duracionHoras: 4,
      fechaVisita: DateTime.now().add(const Duration(days: 12)),
      kind: AdventureKind.personal,
      ubicacion: 'Cerro Norte',
      msnm: 1800,
    ),
    Adventure(
      id: 'adv-2',
      destino: 'Maraton de la Ciudad',
      tipos: const <TipoActividad>{TipoActividad.running},
      estado: EstadoAventura.enPlaneacion,
      dificultad: Dificultad.dura,
      duracionHoras: 5,
      fechaVisita: DateTime.now().add(const Duration(days: 45)),
      kind: AdventureKind.community,
      ubicacion: 'Centro',
      organizadorId: 'user-organizador-1',
      cupo: 200,
      confirmados: List<String>.generate(37, (int i) => 'user-$i'),
    ),
  ];

  @override
  Future<List<Adventure>> misAventuras() async =>
      _aventuras.where((Adventure a) => !a.esComunitaria).toList();

  @override
  Future<List<Adventure>> eventosDeComunidad() async =>
      _aventuras.where((Adventure a) => a.esComunitaria).toList();

  @override
  Future<void> confirmarAsistencia({
    required String aventuraId,
    required String usuarioId,
  }) async {
    final int indice = _aventuras.indexWhere((Adventure a) => a.id == aventuraId);
    if (indice == -1) return;
    final Adventure actual = _aventuras[indice];
    if (actual.confirmados.contains(usuarioId)) return;
    _aventuras[indice] = Adventure(
      id: actual.id,
      destino: actual.destino,
      tipos: actual.tipos,
      estado: actual.estado,
      dificultad: actual.dificultad,
      duracionHoras: actual.duracionHoras,
      fechaVisita: actual.fechaVisita,
      kind: actual.kind,
      ubicacion: actual.ubicacion,
      msnm: actual.msnm,
      organizadorId: actual.organizadorId,
      cupo: actual.cupo,
      confirmados: <String>[...actual.confirmados, usuarioId],
    );
  }
}
