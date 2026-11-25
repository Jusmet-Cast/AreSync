import 'package:flutter/material.dart';

/// Pilar 2. Pendiente de implementar.
///
/// Decidido en diseno: el heroe es lo que FALTA, no lo consumido. El registro
/// entra por foto, voz o codigo de barras. Y el ayuno vive adentro de este
/// pilar, no como modulo aparte: es su eje de tiempo.
class NutritionPage extends StatelessWidget {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colores = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Nutricion', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            Text(
              'Macros, plan de comidas, recetas y ventana de ayuno.',
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
