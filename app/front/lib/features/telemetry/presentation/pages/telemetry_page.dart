import 'package:flutter/material.dart';

/// Pilar 3. Pendiente de implementar contra `ResolverMetricas`.
///
/// Lo que tiene que mostrar, ya decidido en diseno:
///   - Cada metrica con la fuente de la que salio (el modelo agnostico, visible).
///   - Los huecos declarados, no disimulados como cero: hoy falta HRV porque
///     la Xiaomi global no la publica.
///   - La carga aguda/cronica, que no viene de ningun wearable sino de cruzar
///     el volumen de las ultimas 4 semanas con el de la ultima.
class TelemetryPage extends StatelessWidget {
  const TelemetryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Pendiente(
      titulo: 'Telemetria',
      nota: 'Conectar con ResolverMetricas y los adaptadores de '
          'Health Connect / Apple Health.',
    );
  }
}

class _Pendiente extends StatelessWidget {
  const _Pendiente({required this.titulo, required this.nota});

  final String titulo;
  final String nota;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colores = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(titulo, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            Text(
              nota,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: colores.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
