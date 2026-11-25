import 'package:flutter/material.dart';

import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/working_set.dart';
import '../widgets/rir_selector.dart';

/// Sesion de fuerza en curso.
///
/// Es la pantalla mas usada de la app y no es un dashboard: es una tarea.
/// Controles grandes, un solo gesto por serie, y la referencia de la sesion
/// anterior siempre a la vista.
class SessionPage extends StatefulWidget {
  const SessionPage({super.key});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  double _peso = 72.5;
  int _reps = 10;
  int _rir = 1;
  final List<WorkingSet> _series = <WorkingSet>[];

  void _guardar() {
    setState(() {
      _series.add(
        WorkingSet(
          numero: _series.length + 1,
          pesoKg: _peso,
          repeticiones: _reps,
          rir: _rir,
          registradaEn: DateTime.now(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colores = Theme.of(context).colorScheme;
    final TextTheme texto = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Text('Pull · ejercicio 3 de 6',
              style: TextStyle(fontSize: 12, color: colores.onSurfaceVariant)),
          const SizedBox(height: 10),
          Text('Jalon al pecho', style: texto.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'La semana pasada: 70 kg × 10 con 1 en reserva',
            style: TextStyle(fontSize: 12, color: colores.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          _Stepper(
            etiqueta: 'kilos',
            valor: _peso.toStringAsFixed(1),
            onMenos: () =>
                setState(() => _peso = (_peso - 2.5).clamp(0, 500).toDouble()),
            onMas: () => setState(() => _peso += 2.5),
          ),
          const SizedBox(height: 14),
          _Stepper(
            etiqueta: 'repeticiones',
            valor: '$_reps',
            onMenos: () =>
                setState(() => _reps = (_reps - 1).clamp(0, 100).toInt()),
            onMas: () => setState(() => _reps += 1),
          ),
          const SizedBox(height: 22),
          Text('REPETICIONES EN RESERVA', style: texto.labelSmall),
          const SizedBox(height: 8),
          RirSelector(valor: _rir, onChanged: (int v) => setState(() => _rir = v)),
          const SizedBox(height: 20),
          FilledButton(onPressed: _guardar, child: const Text('Guardar serie')),
          const SizedBox(height: 20),
          if (_series.isEmpty)
            Text(
              'Todavia no registraste ninguna serie.',
              style: TextStyle(fontSize: 12, color: colores.onSurfaceVariant),
            )
          else
            Card(
              child: Column(
                children: <Widget>[
                  for (final WorkingSet s in _series)
                    ListTile(
                      dense: true,
                      leading: Text('${s.numero}',
                          style: TextStyle(color: colores.onSurfaceVariant)),
                      title: Text(
                        '${s.pesoKg.toStringAsFixed(1)} kg × ${s.repeticiones}',
                        style: AppTypography.tabular(size: 14),
                      ),
                      trailing: Text(
                        'RIR ${s.rir}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colores.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.etiqueta,
    required this.valor,
    required this.onMenos,
    required this.onMas,
  });

  final String etiqueta;
  final String valor;
  final VoidCallback onMenos;
  final VoidCallback onMas;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colores = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        _BotonRedondo(icono: Icons.remove, onTap: onMenos, etiqueta: 'Bajar $etiqueta'),
        Expanded(
          child: Column(
            children: <Widget>[
              Text(valor, style: AppTypography.tabular(size: 38)),
              Text(
                etiqueta.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colores.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        _BotonRedondo(icono: Icons.add, onTap: onMas, etiqueta: 'Subir $etiqueta'),
      ],
    );
  }
}

class _BotonRedondo extends StatelessWidget {
  const _BotonRedondo({
    required this.icono,
    required this.onTap,
    required this.etiqueta,
  });

  final IconData icono;
  final VoidCallback onTap;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onTap,
      icon: Icon(icono),
      tooltip: etiqueta,
      iconSize: 24,
      // 52 px: tiene que ser tocable con las manos sudadas y sin mirar.
      constraints: const BoxConstraints.tightFor(width: 52, height: 52),
    );
  }
}
