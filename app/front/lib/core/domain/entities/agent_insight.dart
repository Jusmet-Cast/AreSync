/// Severidad de una alerta. Mismo banding en todo el sistema (AEGIS, MOMENTUM
/// y el resto) a proposito: que "rojo" signifique lo mismo venga de donde
/// venga es lo que permite fusionar insights de agentes distintos en una sola
/// pantalla sin que el usuario tenga que aprender una escala por pilar.
enum FlagLevel { info, amarillo, naranja, rojo, critico }

/// Una alerta puntual que un agente levanta. `agente` identifica la fuente
/// (AEGIS, FORGE, NUTRISYNC, MOMENTUM, ...) para que la UI pueda agrupar o
/// filtrar sin perder de donde salio el aviso.
class AgentFlag {
  const AgentFlag({
    required this.agente,
    required this.nivel,
    required this.descripcion,
  });

  final String agente;
  final FlagLevel nivel;
  final String descripcion;
}

/// Contrato base de lo que cualquier agente devuelve. No se instancia
/// directa: cada agente real tiene su propia forma (`sealed` obliga a
/// manejar los cuatro casos conocidos en cualquier `switch`, asi que sumar un
/// agente nuevo el dia de mañana marca todos los lugares que falta tocar).
///
/// Hoy esto lo llena un repositorio mock con datos de ejemplo. El dia que
/// exista el backend (`app/api`) y la orquestacion real de agentes, esta
/// misma forma es lo que ese backend tiene que devolver — el contrato no
/// cambia, cambia quien lo llena.
sealed class AgentInsight {
  const AgentInsight({required this.flags, required this.generadoEn});

  final List<AgentFlag> flags;
  final DateTime generadoEn;

  bool get tieneCritico => flags.any((AgentFlag f) => f.nivel == FlagLevel.critico);
}

/// Espejo de `aegis_output`. Recuperacion, sueño, carga sistemica.
///
/// Cuando `tieneCritico` es true, ninguna pantalla de entreno puede mostrar
/// una progresion de carga sin mostrar primero este aviso — es la misma
/// regla que en AreSync: AEGIS bloquea a FORGE hasta resolucion.
class RecoveryInsight extends AgentInsight {
  const RecoveryInsight({
    required this.iraScore,
    required this.iraEstado,
    required this.recomendacionSesion,
    required this.prioridadSueño,
    this.protocoloRecuperacion,
    this.notaNutricional,
    required super.flags,
    required super.generadoEn,
  });

  /// 0-100, ver `IraCalculator` para como se arma.
  final int iraScore;
  final FlagLevel iraEstado;
  final String recomendacionSesion;
  final FlagLevel prioridadSueño;
  final String? protocoloRecuperacion;
  final String? notaNutricional;
}

/// Espejo de `forge_output`. Programacion, volumen, progresion, PRs.
class TrainingInsight extends AgentInsight {
  const TrainingInsight({
    required this.balanceAdecuado,
    required this.volumenPorGrupo,
    required this.diasSobrecargados,
    required this.estadoProgresion,
    required this.ajusteSesionHoy,
    this.proximaProgresion,
    required super.flags,
    required super.generadoEn,
  });

  final bool balanceAdecuado;

  /// Series por grupo muscular esta semana. Clave = nombre del grupo tal como
  /// vive en Motion Studio (Chest, Back, Shoulders, ...), no traducido: si
  /// este cliente alguna vez sincroniza contra esa base, los nombres ya
  /// coinciden.
  final Map<String, int> volumenPorGrupo;
  final List<String> diasSobrecargados;
  final EstadoProgresion estadoProgresion;
  final String ajusteSesionHoy;
  final String? proximaProgresion;
}

enum EstadoProgresion { progresando, estancado, regresando }

/// Espejo de `nutrisync_output`. Energia, proteina, timing, adherencia.
class NutritionInsight extends AgentInsight {
  const NutritionInsight({
    required this.caloriasObjetivoHoy,
    required this.proteinaObjetivoG,
    required this.adherenciaScore,
    required this.ajustePorTrainingLoad,
    this.recomendacionComida,
    this.notaTiming,
    required super.flags,
    required super.generadoEn,
  });

  final int caloriasObjetivoHoy;
  final int proteinaObjetivoG;

  /// 0-6: el checklist diario de NUTRISYNC (proteina, azucar, alcohol,
  /// comida libre, timing post-entreno, timing pre-sueño). Nunca 0-100 a
  /// proposito — mezclar escalas entre pilares es lo que vuelve ilegible un
  /// dashboard fusionado.
  final int adherenciaScore;
  final String ajustePorTrainingLoad;
  final String? recomendacionComida;
  final String? notaTiming;
}

/// Espejo de `momentum_output`. Consistencia, no rendimiento.
class AdherenceInsight extends AgentInsight {
  const AdherenceInsight({
    required this.tasaRegistro7d,
    required this.tasaAdherencia7d,
    required this.rachaActualDias,
    this.diaMayorRiesgo,
    required this.scoreTotal,
    required this.scoreEntreno,
    required this.scoreNutricion,
    required this.scoreTelemetria,
    required this.scorePr,
    required this.flagIaa,
    required super.flags,
    required super.generadoEn,
  });

  final double tasaRegistro7d;
  final double tasaAdherencia7d;
  final int rachaActualDias;
  final String? diaMayorRiesgo;

  /// IAA — Indice de Adherencia. Los 4 pilares pesan 1:1:1:1 por ahora, ver
  /// `IaaCalculator`: no se recalibra la ponderacion sin 4+ semanas de datos
  /// reales, la misma cautela que aplica MOMENTUM en Notion.
  final double scoreTotal;
  final double scoreEntreno;
  final double scoreNutricion;
  final double scoreTelemetria;
  final double scorePr;
  final FlagLevel flagIaa;
}
