import 'dart:async';

import 'package:flutter/material.dart';

import 'banco.dart';
import 'prova.dart';
import 'progresso.dart';
import 'simulado.dart' show corrigirSimulado;
import 'tela_desempenho.dart' show dataCurta, porcento;
import 'tela_questao.dart';
import 'tela_simulado.dart' show duracaoLegivel, relogioRegressivo;
import 'tema.dart';

/// Lista das provas reais anteriores, pra refazer exatamente como caiu —
/// pedido da Flávia em 20/10/2026. Cada uma entra inteira, na ordem e
/// numeração originais do caderno oficial (tools/validar_provas.py garante
/// isso antes do arquivo existir aqui).
class TelaProvas extends StatefulWidget {
  const TelaProvas({super.key, required this.registro, this.carregar = carregarProvas});

  final RegistroDeProgresso registro;

  /// Trocável nos testes, para não depender do asset real.
  final Future<List<ProvaReal>> Function() carregar;

  @override
  State<TelaProvas> createState() => _TelaProvasState();
}

class _TelaProvasState extends State<TelaProvas> {
  late final Future<List<ProvaReal>> _provas = widget.carregar();

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Provas anteriores'),
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

            if (provas.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Ainda não há nenhuma prova anterior no banco.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: esquema.onSurfaceVariant),
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  'Refaça uma prova real, exatamente como ela caiu: as mesmas questões, na mesma ordem, com o tempo proporcional ao da prova.',
                  style: TextStyle(fontSize: 14, color: esquema.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                for (final p in provas) ...[
                  _CartaoProva(prova: p, registro: widget.registro),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CartaoProva extends StatelessWidget {
  const _CartaoProva({required this.prova, required this.registro});

  final ProvaReal prova;
  final RegistroDeProgresso registro;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final total = prova.questoes.length;
    return Material(
      key: Key('prova-${prova.dados.id}'),
      color: esquema.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: esquema.outline, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TelaFazerProva(
            titulo: prova.dados.nome,
            questoes: prova.questoes,
            registro: registro,
            avisoGabaritoPreliminar: !prova.dados.gabaritoDefinitivoPublicado,
          ),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(prova.dados.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '${prova.dados.cargo} · $total ${total == 1 ? 'questão' : 'questões'}'
                      '${prova.dados.gabaritoDefinitivoPublicado ? '' : ' · gabarito preliminar'}',
                      style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: esquema.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Etapa { preparacao, prova, resultado }

/// Faz uma lista fixa de questões em formato de prova cronometrada — sem
/// matéria, sem tema, sem dica e sem correção até entregar — seja uma prova
/// real anterior inteira (na ordem original) ou um simulado personalizado
/// (questões de várias provas, misturadas com inéditas do banco atual).
class TelaFazerProva extends StatefulWidget {
  const TelaFazerProva({
    super.key,
    required this.titulo,
    required this.questoes,
    required this.registro,
    this.avisoGabaritoPreliminar = false,
    this.relogio = DateTime.now,
  });

  final String titulo;
  final List<Questao> questoes;
  final RegistroDeProgresso registro;

  /// Mostra o aviso de que uma ou outra resposta pode mudar com o recurso.
  final bool avisoGabaritoPreliminar;

  /// Trocável nos testes: o relógio de verdade não cabe num teste.
  final DateTime Function() relogio;

  @override
  State<TelaFazerProva> createState() => _TelaFazerProvaState();
}

class _TelaFazerProvaState extends State<TelaFazerProva> {
  var _etapa = _Etapa.preparacao;
  late final Duration _tempo = const Duration(minutes: 3) * widget.questoes.length;
  final _escolhas = <int, String>{};
  int _indice = 0;
  DateTime? _inicio;
  Timer? _tique;
  ResultadoSimulado? _resultado;
  bool _abandonou = false;

  List<Questao> get _questoes => widget.questoes;
  Duration get _restante => _inicio!.add(_tempo).difference(widget.relogio());

  @override
  void dispose() {
    _tique?.cancel();
    super.dispose();
  }

  void _comecar() {
    setState(() {
      _etapa = _Etapa.prova;
      _inicio = widget.relogio();
    });
    _tique = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restante <= Duration.zero) {
        _entregar();
      } else {
        setState(() {});
      }
    });
  }

  void _entregar() {
    if (_etapa != _Etapa.prova) return;
    _tique?.cancel();
    final resultado = corrigirSimulado(
      questoes: _questoes,
      escolhas: _escolhas,
      inicio: _inicio!,
      fim: widget.relogio(),
      tempoPrevisto: _tempo,
    );
    widget.registro.registrarSimulado(resultado);
    setState(() {
      _resultado = resultado;
      _etapa = _Etapa.resultado;
    });
  }

  Future<void> _confirmarEntrega() async {
    final emBranco = _questoes.length - _escolhas.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entregar a prova?'),
        content: Text(emBranco == 0
            ? 'Todas as questões estão respondidas.'
            : '$emBranco ${emBranco == 1 ? 'questão está' : 'questões estão'} em branco e ${emBranco == 1 ? 'vale' : 'valem'} zero.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Voltar à prova')),
          FilledButton(key: const Key('confirmar-entrega'), onPressed: () => Navigator.pop(context, true), child: const Text('Entregar')),
        ],
      ),
    );
    if (ok == true) _entregar();
  }

  Future<bool> _confirmarSaida() async {
    if (_etapa != _Etapa.prova) return true;
    final sair = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da prova?'),
        content: const Text('A prova será abandonada e as respostas não serão salvas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continuar a prova')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sair')),
        ],
      ),
    );
    return sair == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _etapa != _Etapa.prova || _abandonou,
      onPopInvokedWithResult: (saiu, _) async {
        if (saiu) return;
        if (await _confirmarSaida() && mounted) {
          _tique?.cancel();
          setState(() => _abandonou = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(this.context).pop();
          });
        }
      },
      child: switch (_etapa) {
        _Etapa.preparacao => _Preparacao(
            titulo: widget.titulo,
            total: _questoes.length,
            tempo: _tempo,
            avisoGabaritoPreliminar: widget.avisoGabaritoPreliminar,
            aoComecar: _comecar,
          ),
        _Etapa.prova => _prova(context),
        _Etapa.resultado => _ResultadoProva(titulo: widget.titulo, questoes: _questoes, resultado: _resultado!),
      },
    );
  }

  Widget _prova(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final q = _questoes[_indice];
    final ultima = _indice == _questoes.length - 1;
    final restante = _restante;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Sair da prova',
                    icon: const Icon(Icons.close),
                    color: esquema.onSurfaceVariant,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Semantics(
                      label: 'Questão ${_indice + 1} de ${_questoes.length}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_indice + 1) / _questoes.length,
                          minHeight: 8,
                          color: esquema.primary,
                          backgroundColor: esquema.outline.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    relogioRegressivo(restante),
                    key: const Key('relogio'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: restante.inMinutes < 5 ? Theme.of(context).colorScheme.error : esquema.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                children: [
                  Text('Questão ${_indice + 1} de ${_questoes.length}',
                      style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Text(q.enunciado, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  for (final letra in letras) ...[
                    _AlternativaDaProva(
                      letra: letra,
                      texto: q.alternativas[letra]!,
                      selecionada: _escolhas[_indice] == letra,
                      // Tocar de novo na marcada desmarca: em branco é uma escolha possível.
                      aoTocar: () => setState(() {
                        if (_escolhas[_indice] == letra) {
                          _escolhas.remove(_indice);
                        } else {
                          _escolhas[_indice] = letra;
                        }
                      }),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: esquema.outline))),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _indice == 0 ? null : () => setState(() => _indice--),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: FilledButton(
                      key: Key(ultima ? 'entregar-prova' : 'proxima-questao'),
                      onPressed: ultima ? _confirmarEntrega : () => setState(() => _indice++),
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                      child: Text(ultima ? 'Entregar' : 'Próxima'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Preparacao extends StatelessWidget {
  const _Preparacao({
    required this.titulo,
    required this.total,
    required this.tempo,
    required this.avisoGabaritoPreliminar,
    required this.aoComecar,
  });

  final String titulo;
  final int total;
  final Duration tempo;
  final bool avisoGabaritoPreliminar;
  final VoidCallback aoComecar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(titulo),
        actions: const [BotaoTema()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$total questões · ${duracaoLegivel(tempo)}',
                style: TextStyle(fontSize: 16, color: esquema.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Text(
                'Sem dica e sem correção durante a prova — o resultado e a revisão vêm só no fim, '
                'como na prova de verdade.',
                style: TextStyle(fontSize: 15, color: esquema.onSurfaceVariant, height: 1.4),
              ),
              if (avisoGabaritoPreliminar) ...[
                const SizedBox(height: 16),
                Text(
                  'Uma ou mais dessas provas só têm gabarito preliminar: uma ou outra resposta pode mudar depois do recurso.',
                  style: TextStyle(fontSize: 14, color: esquema.onSurfaceVariant, fontStyle: FontStyle.italic),
                ),
              ],
              const Spacer(),
              FilledButton(
                key: const Key('comecar-prova'),
                onPressed: aoComecar,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                child: const Text('Começar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlternativaDaProva extends StatelessWidget {
  const _AlternativaDaProva({required this.letra, required this.texto, required this.selecionada, required this.aoTocar});

  final String letra;
  final String texto;
  final bool selecionada;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Material(
      key: Key('alternativa-prova-$letra'),
      color: selecionada ? esquema.primaryContainer : esquema.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selecionada ? esquema.primary : esquema.outline, width: selecionada ? 2 : 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selecionada ? esquema.primary : esquema.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: selecionada ? esquema.primary : esquema.outline),
                ),
                child: Text(letra, style: TextStyle(fontWeight: FontWeight.w600, color: selecionada ? esquema.onPrimary : esquema.onSurfaceVariant)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(texto, style: Theme.of(context).textTheme.bodyLarge)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultadoProva extends StatelessWidget {
  const _ResultadoProva({required this.titulo, required this.questoes, required this.resultado});

  final String titulo;
  final List<Questao> questoes;
  final ResultadoSimulado resultado;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final tituloEstilo = TextStyle(fontFamily: fonteTitulo, fontSize: 21, fontWeight: FontWeight.w600, color: esquema.onSurface);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
        title: Text('Resultado · $titulo'),
        actions: const [BotaoTema()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: esquema.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: esquema.outline, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${resultado.acertos} de ${resultado.total}', key: const Key('placar-prova'), style: tituloEstilo.copyWith(fontSize: 28)),
                  Text('${porcento(resultado.acertos / resultado.total)} de acerto · ${dataCurta(resultado.inicio)}',
                      style: TextStyle(fontSize: 14, color: esquema.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Revisão das questões', style: tituloEstilo),
            const SizedBox(height: 4),
            for (var i = 0; i < questoes.length; i++)
              _LinhaRevisaoProva(numero: i + 1, questao: questoes[i], resposta: resultado.respostas[i]),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinhaRevisaoProva extends StatelessWidget {
  const _LinhaRevisaoProva({required this.numero, required this.questao, required this.resposta});

  final int numero;
  final Questao questao;
  final Resposta resposta;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final cores = Cores.de(context);
    final branco = resposta.escolhida == semResposta;
    return ListTile(
      key: Key('revisao-prova-$numero'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        resposta.acertou ? Icons.check_circle : Icons.cancel,
        color: resposta.acertou ? cores.acerto : cores.erro,
      ),
      title: Text('Questão $numero', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(
        branco ? 'Em branco · correta: ${questao.correta}' : 'Sua: ${resposta.escolhida} · correta: ${questao.correta}',
        style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant),
      ),
      trailing: Icon(Icons.chevron_right, color: esquema.onSurfaceVariant),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TelaRevisaoQuestao(
          questao: questao,
          nomeDaMateria: nomesDasMaterias[questao.materia] ?? questao.materia,
          escolhida: branco ? null : resposta.escolhida,
        ),
      )),
    );
  }
}
