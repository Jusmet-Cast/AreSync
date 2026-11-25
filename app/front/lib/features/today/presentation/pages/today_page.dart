import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/entities/agent_insight.dart';
import '../../../../core/domain/entities/arc.dart';
import '../../../../core/providers.dart';
import '../../../coach/presentation/providers.dart';

T? _primero<T>(Iterable<Object?> items) {
  for (final Object? item in items) {
    if (item is T) return item;
  }
  return null;
}

/// Entrada de la app: el veredicto del coach y los pilares.
///
/// Los pilares son la estructura de la pantalla, no un menu: lo que justifica
/// que FitCodex exista es la decision que sale de cruzarlos, y esa decision
/// va arriba de todo. Generica a proposito: todo lo que se muestra sale del
/// Arc activo y del snapshot de agentes, nunca de un dato fijo de una sola
/// persona.
class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Arc?> arc = ref.watch(arcActivoProvider);
    final AsyncValue<List<AgentInsight>?> snapshot = ref.watch(coachSnapshotProvider);
    final ColorScheme colores = Theme.of(context).colorScheme;
    final TextTheme texto = Theme.of(context).textTheme;

    return SafeArea(
      child: arc.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text('No se pudo cargar el Arc: $e')),
        data: (Arc? arcActivo) {
          if (arcActivo == null) {
            return _SinArc(colores: colores, texto: texto);
          }

          final List<AgentInsight> insights = snapshot.valueOrNull ?? <AgentInsight>[];
          final RecoveryInsight? recovery = _primero<RecoveryInsight>(insights);
          final TrainingInsight? training = _primero<TrainingInsight>(insights);
          final NutritionInsight? nutrition = _primero<NutritionInsight>(insights);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: Text('FitCodex', style: texto.titleLarge)),
                  Chip(
                    label: Text(arcActivo.nombre),
                    backgroundColor: colores.primaryContainer,
                    labelStyle: TextStyle(fontSize: 11, color: colores.onPrimaryContainer),
                    side: BorderSide.none,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Icon(Icons.auto_awesome, size: 14, color: colores.primary),
                  const SizedBox(width: 7),
                  Text('EL COACH', style: texto.labelSmall?.copyWith(color: colores.primary)),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                recovery == null
                    ? 'Todavia no hay snapshot del coach para hoy.'
                    : recovery.recomendacionSesion,
                style: texto.headlineMedium,
              ),
              if (training != null) ...<Widget>[
                const SizedBox(height: 9),
                Text(
                  training.ajusteSesionHoy,
                  style: TextStyle(fontSize: 13, height: 1.5, color: colores.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 22),
              Text('LOS PILARES', style: texto.labelSmall),
              const SizedBox(height: 10),
              _Pilar(
                icono: Icons.fitness_center_outlined,
                titulo: 'Entrenamiento',
                detalle: training == null
                    ? 'Sin datos de la semana todavia'
                    : 'Volumen: ${training.volumenPorGrupo.entries.map((MapEntry<String, int> e) => '${e.key} ${e.value}').join(' · ')}',
                onTap: () => context.go('/entreno'),
              ),
              const SizedBox(height: 9),
              _Pilar(
                icono: Icons.restaurant_outlined,
                titulo: 'Nutricion',
                detalle: nutrition == null
                    ? 'Sin datos de hoy todavia'
                    : '${nutrition.proteinaObjetivoG} g de proteina objetivo · ${nutrition.caloriasObjetivoHoy} kcal',
                onTap: () => context.go('/nutricion'),
              ),
              const SizedBox(height: 9),
              _Pilar(
                icono: Icons.monitor_heart_outlined,
                titulo: 'Telemetria',
                detalle: recovery == null ? 'Sin datos todavia' : 'IRA ${recovery.iraScore}/100',
                onTap: () => context.go('/telemetria'),
              ),
              const SizedBox(height: 9),
              _Pilar(
                icono: Icons.terrain_outlined,
                titulo: 'Aventuras',
                detalle: 'Retos propios y eventos de comunidad',
                onTap: () => context.push('/aventuras'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SinArc extends StatelessWidget {
  const _SinArc({required this.colores, required this.texto});

  final ColorScheme colores;
  final TextTheme texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Todavia no tenes un Arc activo', style: texto.headlineMedium),
          const SizedBox(height: 10),
          Text(
            'Un Arc es tu objetivo: que queres lograr y en cuanto tiempo. '
            'Todo lo demas (entreno, nutricion, telemetria) se ordena alrededor '
            'de el.',
            style: TextStyle(fontSize: 13, height: 1.5, color: colores.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          const FilledButton(onPressed: null, child: Text('Crear mi primer Arc (pronto)')),
        ],
      ),
    );
  }
}

class _Pilar extends StatelessWidget {
  const _Pilar({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colores = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        onTap: onTap,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colores.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icono, size: 18, color: colores.primary),
        ),
        title: Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(detalle, style: TextStyle(fontSize: 11.5, color: colores.onSurfaceVariant)),
        trailing: Icon(Icons.chevron_right, color: colores.onSurfaceVariant),
      ),
    );
  }
}
