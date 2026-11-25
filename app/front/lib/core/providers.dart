import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/repositories/mock_arc_repository.dart';
import 'domain/entities/arc.dart';
import 'domain/entities/user_profile.dart';
import 'domain/ports/arc_repository.dart';

/// Unica instancia del repo de Arcs para toda la app. Cambiar el mock por la
/// implementacion real (Drift + sync contra `app/api`) es tocar esta linea,
/// ninguna pantalla referencia `MockArcRepository` directamente.
final Provider<ArcRepository> arcRepositoryProvider = Provider<ArcRepository>(
  (Ref ref) => MockArcRepository(),
);

final FutureProvider<Arc?> arcActivoProvider = FutureProvider<Arc?>(
  (Ref ref) => ref.watch(arcRepositoryProvider).arcActivo(),
);

/// Perfil del usuario actual. Seed generico: no hay backend de auth todavia,
/// asi que esto representa "quien esta usando la app ahora mismo" hasta que
/// exista login real.
final Provider<UserProfile> userProfileProvider = Provider<UserProfile>(
  (Ref ref) => const UserProfile(
    id: 'usuario-local',
    nombre: 'Vos',
    nivel: ExperienceLevel.constante,
    unidadPeso: UnidadPeso.kg,
  ),
);
