import '../../../../core/domain/entities/agent_insight.dart';

/// Un turno de conversacion con el coach. `insightsRelevantes` deja que una
/// respuesta en texto venga acompañada de la forma estructurada que la
/// genero (ej. el chat dice "bajale intensidad hoy" y adjunta el
/// `RecoveryInsight` completo de AEGIS que lo justifica) — la UI puede
/// mostrar ambos sin que el chat tenga que describir el numero en prosa.
class CoachReply {
  const CoachReply({
    required this.texto,
    this.insightsRelevantes = const <AgentInsight>[],
  });

  final String texto;
  final List<AgentInsight> insightsRelevantes;
}

/// Contrato para invocar a los agentes (AEGIS, FORGE, NUTRISYNC, MOMENTUM,
/// ...) que hoy viven como prompts en el repo de AreSync y corren vía chat
/// con un LLM externo, no dentro del cliente Flutter.
///
/// Esta interfaz es la frontera entre la app y esa orquestacion. La
/// implementacion real (`app/api`) es la que decide que LLM invocar, con que
/// contexto de Notion/backend, y en que orden consultar cada agente — el
/// cliente nunca habla con el LLM directo. Hoy solo existe un mock que
/// devuelve insights de ejemplo para poder construir la UI del Coach sin
/// esperar a que el backend exista.
abstract interface class AgentOrchestrator {
  /// Snapshot de todos los agentes relevantes para el Arc activo, sin que el
  /// usuario tenga que preguntar nada — lo que alimenta el hero de "Hoy".
  Future<List<AgentInsight>> obtenerSnapshot({required String arcId});

  /// Una pregunta libre del usuario ("¿como vengo esta semana?", "que como
  /// hoy"). El orquestador real decide que agente(s) activar, igual que hace
  /// AreSync Core hoy via chat.
  Future<CoachReply> preguntar({required String arcId, required String mensaje});
}
