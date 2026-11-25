import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_adventure_repository.dart';
import '../domain/entities/adventure.dart';
import '../domain/ports/adventure_repository.dart';

final Provider<AdventureRepository> adventureRepositoryProvider =
    Provider<AdventureRepository>((Ref ref) => MockAdventureRepository());

final FutureProvider<List<Adventure>> misAventurasProvider =
    FutureProvider<List<Adventure>>(
        (Ref ref) => ref.watch(adventureRepositoryProvider).misAventuras());

final FutureProvider<List<Adventure>> eventosDeComunidadProvider =
    FutureProvider<List<Adventure>>(
        (Ref ref) => ref.watch(adventureRepositoryProvider).eventosDeComunidad());
