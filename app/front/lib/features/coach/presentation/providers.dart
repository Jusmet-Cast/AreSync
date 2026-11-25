import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/agent_insight.dart';
import '../../../core/providers.dart';
import '../data/mock_agent_orchestrator.dart';
import '../domain/ports/agent_orchestrator.dart';

final Provider<AgentOrchestrator> agentOrchestratorProvider =
    Provider<AgentOrchestrator>((Ref ref) => const MockAgentOrchestrator());

/// Snapshot de todos los agentes para el Arc activo. `null` mientras no haya
/// Arc activo: ningun agente tiene contra que medir sin uno, asi que la UI
/// tiene que mostrar "setea tu primer Arc" en vez de un dashboard vacio.
final FutureProvider<List<AgentInsight>?> coachSnapshotProvider =
    FutureProvider<List<AgentInsight>?>((Ref ref) async {
  final arc = await ref.watch(arcActivoProvider.future);
  if (arc == null) return null;
  return ref.watch(agentOrchestratorProvider).obtenerSnapshot(arcId: arc.id);
});
