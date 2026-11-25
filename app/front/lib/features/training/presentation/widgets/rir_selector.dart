import 'package:flutter/material.dart';

/// Selector de repeticiones en reserva.
///
/// Estado local a proposito: es una preferencia de la serie en curso, no algo
/// que otra pantalla necesite. Lo que si sube a Riverpod es la serie ya
/// guardada.
class RirSelector extends StatelessWidget {
  const RirSelector({required this.valor, required this.onChanged, super.key});

  final int valor;
  final ValueChanged<int> onChanged;

  static const List<int> _opciones = <int>[0, 1, 2, 3, 4];

  @override
  Widget build(BuildContext context) {
    final ColorScheme colores = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        for (final int v in _opciones) ...<Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(v),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: v == valor ? colores.primary : null,
                  border: Border.all(color: colores.outlineVariant),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  v == 4 ? '4+' : '$v',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: v == valor ? FontWeight.w700 : FontWeight.w400,
                    color: v == valor
                        ? colores.onPrimary
                        : colores.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          if (v != _opciones.last) const SizedBox(width: 7),
        ],
      ],
    );
  }
}
