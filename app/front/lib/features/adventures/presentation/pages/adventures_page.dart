import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/adventure.dart';
import '../providers.dart';

/// Retos personales y eventos de comunidad en una sola pantalla con dos
/// pestañas. Separados a proposito (ver `AdventureKind`): un reto propio no
/// tiene cupo ni organizador, un evento de comunidad si — mezclarlos en una
/// lista unica obliga a mostrar campos vacios la mitad del tiempo.
class AdventuresPage extends ConsumerWidget {
  const AdventuresPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Aventuras'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Mis retos'),
              Tab(text: 'Comunidad'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _ListaAventuras(provider: misAventurasProvider),
            _ListaAventuras(provider: eventosDeComunidadProvider),
          ],
        ),
      ),
    );
  }
}

class _ListaAventuras extends ConsumerWidget {
  const _ListaAventuras({required this.provider});

  final FutureProvider<List<Adventure>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Adventure>> aventuras = ref.watch(provider);
    final ColorScheme colores = Theme.of(context).colorScheme;

    return aventuras.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, _) => Center(child: Text('Error: $e')),
      data: (List<Adventure> lista) {
        if (lista.isEmpty) {
          return const Center(child: Text('Todavia no hay nada por aca.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: lista.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int i) {
            final Adventure a = lista[i];
            return Card(
              child: ListTile(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                title: Text(a.destino, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  a.esComunitaria
                      ? '${a.confirmados.length}${a.cupo != null ? '/${a.cupo}' : ''} confirmados · en ${a.diasRestantes} dias'
                      : '${a.dificultad.name} · en ${a.diasRestantes} dias',
                  style: TextStyle(fontSize: 12, color: colores.onSurfaceVariant),
                ),
                trailing: a.esComunitaria
                    ? FilledButton.tonal(
                        onPressed: a.tieneCupoDisponible ? () {} : null,
                        child: Text(a.tieneCupoDisponible ? 'Sumarme' : 'Sin cupo'),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}
