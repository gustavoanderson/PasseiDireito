import 'package:flutter/material.dart';

import 'log.dart';
import 'tela_desempenho.dart' show dataCurta;
import 'tema.dart';

String _rotuloDoTipo(TipoEvento t) => switch (t) {
      TipoEvento.edital => 'EDITAL',
      TipoEvento.remocao => 'SAIU DO BANCO',
      TipoEvento.ajuste => 'AJUSTE',
      TipoEvento.criacao => 'ENTROU NO BANCO',
    };

/// A cronologia do que mudou no banco por causa do edital: o que saiu, o
/// que entrou e quando — pedido do Gustavo e da Flávia em 14/10/2026, pra
/// ela conferir por conta própria, sem precisar perguntar.
class TelaLog extends StatefulWidget {
  const TelaLog({super.key, this.carregar = carregarLogDeAlteracoes});

  /// Trocável nos testes, para não depender do asset real.
  final Future<LogDeAlteracoes> Function() carregar;

  @override
  State<TelaLog> createState() => _TelaLogState();
}

class _TelaLogState extends State<TelaLog> {
  late final Future<LogDeAlteracoes> _log = widget.carregar();

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Log de alterações'),
        actions: const [BotaoTema()],
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: _log,
          builder: (context, estado) {
            if (estado.hasError) {
              return Center(child: Text('Não consegui abrir o log.\n${estado.error}'));
            }
            if (!estado.hasData) return const Center(child: CircularProgressIndicator());
            final log = estado.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  log.introducao,
                  style: TextStyle(fontSize: 14, color: esquema.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Text(
                  'Atualizado em ${dataCurta(log.atualizadoEm)}',
                  style: TextStyle(fontSize: 12, color: esquema.onSurfaceVariant, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),
                for (final e in log.doMaisRecente) _CartaoEvento(evento: e),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CartaoEvento extends StatelessWidget {
  const _CartaoEvento({required this.evento});

  final EventoDoLog evento;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final cores = Cores.de(context);
    final (cor, corTexto, icone) = switch (evento.tipo) {
      TipoEvento.edital => (esquema.primary, esquema.primary, Icons.gavel_outlined),
      TipoEvento.remocao => (cores.erro, cores.erroTexto, Icons.remove_circle_outline),
      TipoEvento.criacao => (cores.acerto, cores.acertoTexto, Icons.add_circle_outline),
      TipoEvento.ajuste => (cores.dica, cores.dicaTexto, Icons.tune),
    };
    final ids = evento.questoesRemovidas.isNotEmpty ? evento.questoesRemovidas : evento.questoesCriadas;
    final rotuloIds = evento.questoesRemovidas.isNotEmpty
        ? '${ids.length} ${ids.length == 1 ? 'questão removida' : 'questões removidas'}'
        : '${ids.length} ${ids.length == 1 ? 'questão nova' : 'questões novas'}';

    return Container(
      key: Key('evento-${evento.data.toIso8601String()}-${evento.titulo}'),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: esquema.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: esquema.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: cor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icone, size: 16, color: corTexto),
                        const SizedBox(width: 6),
                        Text(
                          _rotuloDoTipo(evento.tipo),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: corTexto),
                        ),
                        const Spacer(),
                        Text(dataCurta(evento.data), style: TextStyle(fontSize: 12, color: esquema.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(evento.titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(evento.descricao, style: TextStyle(fontSize: 14, color: esquema.onSurfaceVariant, height: 1.4)),
                    if (ids.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Material(
                        type: MaterialType.transparency,
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            key: Key('expandir-${evento.titulo}'),
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.zero,
                            title: Text(rotuloIds, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: corTexto)),
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    ids.join(', '),
                                    style: TextStyle(fontSize: 12, color: esquema.onSurfaceVariant),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (evento.commit != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'commit ${evento.commit}',
                        style: TextStyle(fontSize: 11, color: esquema.onSurfaceVariant.withValues(alpha: 0.7)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
