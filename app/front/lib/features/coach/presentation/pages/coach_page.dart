import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../providers.dart';

/// Chat del coach. Hoy pregunta y respuesta via `MockAgentOrchestrator`;
/// el dia que `app/api` orqueste los agentes reales, esta pantalla no
/// cambia — solo cambia que implementacion de `AgentOrchestrator` resuelve
/// el provider.
class CoachPage extends ConsumerStatefulWidget {
  const CoachPage({super.key});

  @override
  ConsumerState<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends ConsumerState<CoachPage> {
  final TextEditingController _controlador = TextEditingController();
  final List<_Mensaje> _mensajes = <_Mensaje>[];
  bool _enviando = false;

  Future<void> _enviar() async {
    final String texto = _controlador.text.trim();
    if (texto.isEmpty || _enviando) return;

    setState(() {
      _mensajes.add(_Mensaje(texto: texto, esDelUsuario: true));
      _controlador.clear();
      _enviando = true;
    });

    final arc = await ref.read(arcActivoProvider.future);
    final respuesta = await ref
        .read(agentOrchestratorProvider)
        .preguntar(arcId: arc?.id ?? '', mensaje: texto);

    if (!mounted) return;
    setState(() {
      _mensajes.add(_Mensaje(texto: respuesta.texto, esDelUsuario: false));
      _enviando = false;
    });
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Coach')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _mensajes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Pregunta lo que quieras sobre tu entreno, nutricion o '
                        'recuperacion. El coach orquesta a los agentes por vos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colores.onSurfaceVariant),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _mensajes.length,
                    itemBuilder: (BuildContext context, int i) {
                      final _Mensaje m = _mensajes[i];
                      return Align(
                        alignment:
                            m.esDelUsuario ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: m.esDelUsuario
                                ? colores.primaryContainer
                                : colores.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(m.texto),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _controlador,
                      decoration: const InputDecoration(hintText: 'Escribile al coach...'),
                      onSubmitted: (_) => _enviar(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _enviando ? null : _enviar,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Mensaje {
  const _Mensaje({required this.texto, required this.esDelUsuario});
  final String texto;
  final bool esDelUsuario;
}
