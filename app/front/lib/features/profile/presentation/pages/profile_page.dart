import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/entities/user_profile.dart';
import '../../../../core/providers.dart';

/// Perfil y nivel.
///
/// Decidido en diseno: el nivel (Base / Constante / Serio) no se desbloquea
/// pagando sino cuando ya existen los datos que lo vuelven util, con criterios
/// medibles a la vista y una salida manual para el que ya entrena hace anos.
/// El nivel sale de `userProfileProvider`, nunca de un literal en esta
/// pantalla: asi dos usuarios de la misma app ven su propio nivel.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserProfile perfil = ref.watch(userProfileProvider);
    final ColorScheme colores = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(perfil.nombre, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Chip(
              label: Text('Nivel ${perfil.nivel.etiqueta}'),
              backgroundColor: colores.primaryContainer,
              labelStyle: TextStyle(fontSize: 11, color: colores.onPrimaryContainer),
              side: BorderSide.none,
            ),
            const SizedBox(height: 14),
            Text(
              'Nivel, criterios de progresion y fuentes de datos conectadas.',
              style: TextStyle(fontSize: 13, height: 1.5, color: colores.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
