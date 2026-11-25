import '../entities/adventure.dart';

abstract interface class AdventureRepository {
  Future<List<Adventure>> misAventuras();
  Future<List<Adventure>> eventosDeComunidad();
  Future<void> confirmarAsistencia({required String aventuraId, required String usuarioId});
}
