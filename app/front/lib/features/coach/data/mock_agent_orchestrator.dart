import '../../../core/domain/calculators/iaa_calculator.dart';
import '../../../core/domain/calculators/ira_calculator.dart';
import '../../../core/domain/entities/agent_insight.dart';
import '../domain/ports/agent_orchestrator.dart';

/// Devuelve insights de ejemplo, calculados con las formulas reales
/// (`IraCalculator`, `IaaCalculator`) sobre datos de muestra en vez de datos
/// inventados sueltos — asi el mock se comporta como se comportaria el
/// backend real el dia que exista, solo que con un wearable simulado en vez
/// de uno conectado.
class MockAgentOrchestrator implements AgentOrchestrator {
  const MockAgentOrchestrator();

  @override
  Future<List<AgentInsight>> obtenerSnapshot({required String arcId}) async {
    final DateTime ahora = DateTime.now();

    const IraCalculator ira = IraCalculator();
    final int iraScore = ira.calcular(
      const IraInputs(
        rhrBpm: 58,
        sleepScore: 74,
        cargaSemanal: 410,
        vitalityScore7d: 55,
      ),
    );
    final FlagLevel iraEstado = ira.estadoDe(iraScore);

    const IaaCalculator iaa = IaaCalculator();
    const IaaInputs iaaInputs = IaaInputs(
      scoreEntreno: 85,
      scoreNutricion: 72,
      scoreTelemetria: 90,
      scorePr: 70,
    );
    final double iaaTotal = iaa.calcular(iaaInputs);

    return <AgentInsight>[
      RecoveryInsight(
        iraScore: iraScore,
        iraEstado: iraEstado,
        recomendacionSesion: iraEstado == FlagLevel.info
            ? 'Sesion completa segun plan.'
            : 'Completa el plan pero baja un 10-15% la intensidad.',
        prioridadSueño: FlagLevel.amarillo,
        protocoloRecuperacion: 'Target de sueño: acostarse antes de las 00:30.',
        flags: const <AgentFlag>[],
        generadoEn: ahora,
      ),
      TrainingInsight(
        balanceAdecuado: true,
        volumenPorGrupo: const <String, int>{'Back': 14, 'Chest': 12, 'Legs': 16},
        diasSobrecargados: const <String>[],
        estadoProgresion: EstadoProgresion.progresando,
        ajusteSesionHoy: 'Mante la carga de la semana pasada, el volumen esta en rango.',
        flags: const <AgentFlag>[],
        generadoEn: ahora,
      ),
      NutritionInsight(
        caloriasObjetivoHoy: 2400,
        proteinaObjetivoG: 160,
        adherenciaScore: 5,
        ajustePorTrainingLoad: 'Carga normal: TDEE de entrenamiento, proteina en rango medio.',
        recomendacionComida: 'Suma una fuente de proteina magra en la cena.',
        flags: const <AgentFlag>[],
        generadoEn: ahora,
      ),
      AdherenceInsight(
        tasaRegistro7d: 0.86,
        tasaAdherencia7d: 0.78,
        rachaActualDias: 6,
        scoreTotal: iaaTotal,
        scoreEntreno: iaaInputs.scoreEntreno,
        scoreNutricion: iaaInputs.scoreNutricion,
        scoreTelemetria: iaaInputs.scoreTelemetria,
        scorePr: iaaInputs.scorePr,
        flagIaa: iaa.flagDe(iaaTotal),
        flags: const <AgentFlag>[],
        generadoEn: ahora,
      ),
    ];
  }

  @override
  Future<CoachReply> preguntar({required String arcId, required String mensaje}) async {
    return const CoachReply(
      texto: 'El orquestador real todavia no esta conectado — este es un '
          'coach de ejemplo mientras se construye app/api.',
    );
  }
}
