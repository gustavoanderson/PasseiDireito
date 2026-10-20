import 'dart:math';

import 'package:flutter/material.dart';

import 'banco.dart';
import 'progresso.dart';
import 'prova.dart';
import 'tela_provas.dart' show TelaFazerProva;
import 'tema.dart';

const _opcoesDeInediticas = [0, 10, 20, 30, 50];

/// Monta um simulado sob medida: escolher quais provas reais anteriores
/// entram (pode misturar mais de um ano) e, se quiser, somar questões
/// inéditas do banco atual — pedido da Flávia em 20/10/2026. Pergunta a
/// composição antes de gerar, em vez de sortear sozinho.
class TelaSimuladoPersonalizado extends StatefulWidget {
  const TelaSimuladoPersonalizado({
    super.key,
    required this.unidades,
    required this.registro,
    this.carregar = carregarProvas,
    this.sorteio,
  });

  final List<Unidade> unidades;
  final RegistroDeProgresso registro;

  /// Trocável nos testes, para não depender do asset real.
  final Future<List<ProvaReal>> Function() carregar;

  /// Trocável nos testes: o acaso não cabe num teste.
  final Random? sorteio;

  @override
  State<TelaSimuladoPersonalizado> createState() => _TelaSimuladoPersonalizadoState();
}

class _TelaSimuladoPersonalizadoState extends State<TelaSimuladoPersonalizado> {
  late final Future<List<ProvaReal>> _provas = widget.carregar();
  final _provasEscolhidas = <String>{};
  bool _somarIneditas = false;
  int _quantidadeDeIneditas = 20;

  List<Questao> get _todasAsInediticas => [for (final u in widget.unidades) ...u.questoes];

  int _totalEscolhido(List<ProvaReal> provas) {
    final dasProvas = [
      for (final p in provas) if (_provasEscolhidas.contains(p.dados.id)) p.questoes.length,
    ].fold(0, (s, n) => s + n);
    final deIneditas = _somarIneditas ? min(_quantidadeDeIneditas, _todasAsInediticas.length) : 0;
    return dasProvas + deIneditas;
  }

  void _gerar(List<ProvaReal> provas) {
    final escolhidas = provas.where((p) => _provasEscolhidas.contains(p.dados.id)).toList();
    final questoes = [for (final p in escolhidas) ...p.questoes];

    if (_somarIneditas) {
      final ineditas = [..._todasAsInediticas]..shuffle(widget.sorteio ?? Random());
      questoes.addAll(ineditas.take(_quantidadeDeIneditas));
    }
    questoes.shuffle(widget.sorteio ?? Random());

    final algumaPreliminar = escolhidas.any((p) => !p.dados.gabaritoDefinitivoPublicado);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TelaFazerProva(
        titulo: 'Simulado personalizado',
        questoes: questoes,
        registro: widget.registro,
        avisoGabaritoPreliminar: algumaPreliminar,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Simulado personalizado'),
        actions: const [BotaoTema()],
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: _provas,
          builder: (context, estado) {
            if (estado.hasError) {
              return Center(child: Text('Não consegui abrir as provas anteriores.\n${estado.error}'));
            }
            if (!estado.hasData) return const Center(child: CircularProgressIndicator());
            final provas = estado.data!;
            final total = _totalEscolhido(provas);

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    children: [
                      Text(
                        'Escolha quais provas entram no simulado. Pode combinar mais de uma, e somar questões inéditas do banco atual.',
                        style: TextStyle(fontSize: 14, color: esquema.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      if (provas.isEmpty)
                        Text(
                          'Ainda não há nenhuma prova anterior no banco.',
                          style: TextStyle(fontSize: 14, color: esquema.onSurfaceVariant),
                        )
                      else
                        for (final p in provas)
                          CheckboxListTile(
                            key: Key('escolher-${p.dados.id}'),
                            contentPadding: EdgeInsets.zero,
                            value: _provasEscolhidas.contains(p.dados.id),
                            onChanged: (marcado) => setState(() {
                              if (marcado == true) {
                                _provasEscolhidas.add(p.dados.id);
                              } else {
                                _provasEscolhidas.remove(p.dados.id);
                              }
                            }),
                            title: Text(p.dados.nome),
                            subtitle: Text('${p.dados.cargo} · ${p.questoes.length} questões'),
                          ),
                      const Divider(height: 32),
                      CheckboxListTile(
                        key: const Key('somar-ineditas'),
                        contentPadding: EdgeInsets.zero,
                        value: _somarIneditas,
                        onChanged: (marcado) => setState(() => _somarIneditas = marcado ?? false),
                        title: const Text('Somar questões inéditas do banco atual'),
                        subtitle: const Text('Sorteadas do banco inteiro, sem olhar o que você já respondeu.'),
                      ),
                      if (_somarIneditas) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final n in _opcoesDeInediticas)
                              ChoiceChip(
                                key: Key('quantidade-ineditas-$n'),
                                label: Text('$n'),
                                selected: _quantidadeDeIneditas == n,
                                onSelected: (_) => setState(() => _quantidadeDeIneditas = n),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: esquema.outline))),
                  child: FilledButton(
                    key: const Key('gerar-simulado-personalizado'),
                    onPressed: total == 0 ? null : () => _gerar(provas),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                    child: Text(total == 0 ? 'Escolha ao menos uma fonte' : 'Gerar simulado · $total questões'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
