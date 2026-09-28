import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'banco.dart';
import 'desempenho.dart';
import 'progresso.dart';
import 'simulado.dart';
import 'tela_desempenho.dart' show porcento;
import 'tela_questao.dart';
import 'tema.dart';
import 'trilha.dart';

String duracaoLegivel(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return '$m min';
  return m == 0 ? '${h}h' : '${h}h ${m}min';
}

String relogioRegressivo(Duration d) {
  final s = d.isNegative ? Duration.zero : d;
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(s.inHours)}:${dois(s.inMinutes % 60)}:${dois(s.inSeconds % 60)}';
}

enum _Etapa { preparacao, prova, resultado }

/// O simulado da prova objetiva, numa tela só com três etapas.
///
/// Regras do edital e do Gustavo: sem dica, sem consulta, sem correção durante
/// a prova, e NENHUM tema ou matéria na tela da questão. O feedback, com
/// matérias e assuntos a reforçar, vem só no resultado.
class TelaSimulado extends StatefulWidget {
  const TelaSimulado({
    super.key,
    required this.unidades,
    required this.registro,
    this.relogio = DateTime.now,
    this.sorteio,
  });

  final List<Unidade> unidades;
  final RegistroDeProgresso registro;

  /// Trocáveis nos testes: o relógio de verdade e o acaso não cabem num teste.
  final DateTime Function() relogio;
  final Random? sorteio;

  @override
  State<TelaSimulado> createState() => _TelaSimuladoState();
}

class _TelaSimuladoState extends State<TelaSimulado> {
  var _etapa = _Etapa.preparacao;
  late final List<Questao> _questoes =
      sortearSimulado(agruparPorMateria(widget.unidades), widget.sorteio ?? Random());
  late final Duration _tempo = tempoDoSimulado(_questoes.length);
  final _escolhas = <int, String>{};
  final _marcadas = <int>{};
  int _indice = 0;
  DateTime? _inicio;
  Timer? _tique;
  ResultadoSimulado? _resultado;
  bool _abandonou = false;

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
    // O relógio de verdade manda; o tique só redesenha. Se o app ficar em
    // segundo plano, o tempo continua correndo, como na prova.
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
        title: const Text('Entregar o simulado?'),
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
        title: const Text('Sair do simulado?'),
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
          // O pop só pode sair depois que o PopScope for redesenhado liberando.
          setState(() => _abandonou = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(this.context).pop();
          });
        }
      },
      child: switch (_etapa) {
        _Etapa.preparacao => _Preparacao(questoes: _questoes.length, tempo: _tempo, aoComecar: _comecar),
        _Etapa.prova => _prova(context),
        _Etapa.resultado => _ResultadoSimulado(resultado: _resultado!, questoes: _questoes, unidades: widget.unidades),
      },
    );
  }

  Widget _prova(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final q = _questoes[_indice];
    final ultima = _indice == _questoes.length - 1;
    final restante = _restante;
    final acabando = restante < const Duration(minutes: 10);
    final cores = Cores.de(context);
    final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Sair do simulado',
                    icon: const Icon(Icons.close),
                    color: esquema.onSurfaceVariant,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: TextButton(
                      key: const Key('mapa-questoes'),
                      onPressed: () => _abrirMapa(context),
                      style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                      child: Text(
                        'Questão ${_indice + 1} de ${_questoes.length}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: esquema.onSurface),
                      ),
                    ),
                  ),
                  Container(
                    key: const Key('cronometro'),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: acabando ? cores.erroSuave : esquema.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: acabando ? cores.erroTexto : esquema.primary),
                        const SizedBox(width: 6),
                        Text(
                          relogioRegressivo(restante),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: acabando ? cores.erroTexto : esquema.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const BotaoTema(),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                key: ValueKey('questao-$_indice'),
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                children: [
                  // Sem matéria e sem tema: regra do simulado.
                  Text(q.enunciado, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  for (final letra in letras) ...[
                    _AlternativaSimulado(
                      letra: letra,
                      texto: q.alternativas[letra]!,
                      marcada: _escolhas[_indice] == letra,
                      aoTocar: () => setState(() {
                        // Tocar de novo na marcada desmarca: em branco é uma escolha possível.
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
                  OutlinedButton(
                    key: const Key('anterior'),
                    onPressed: _indice == 0 ? null : () => setState(() => _indice--),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), shape: forma),
                    child: const Text('Anterior'),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    key: const Key('marcar'),
                    tooltip: _marcadas.contains(_indice) ? 'Desmarcar revisão' : 'Marcar para revisar',
                    isSelected: _marcadas.contains(_indice),
                    icon: const Icon(Icons.bookmark_border),
                    selectedIcon: const Icon(Icons.bookmark),
                    onPressed: () => setState(() {
                      if (!_marcadas.remove(_indice)) _marcadas.add(_indice);
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      key: Key(ultima ? 'entregar' : 'proxima'),
                      onPressed: ultima ? _confirmarEntrega : () => setState(() => _indice++),
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 48), shape: forma),
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

  void _abrirMapa(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (contexto) {
        final esquema = Theme.of(contexto).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${_escolhas.length} respondidas · ${_questoes.length - _escolhas.length} em branco · ${_marcadas.length} marcadas',
                  style: TextStyle(fontSize: 14, color: esquema.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < _questoes.length; i++)
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(contexto);
                                setState(() => _indice = i);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: _escolhas.containsKey(i) ? esquema.primaryContainer : null,
                                side: BorderSide(
                                  color: _marcadas.contains(i) ? Cores.de(contexto).dica : esquema.outline,
                                  width: _marcadas.contains(i) ? 2 : 1,
                                ),
                              ),
                              child: Text('${i + 1}'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Preparacao extends StatelessWidget {
  const _Preparacao({required this.questoes, required this.tempo, required this.aoComecar});

  final int questoes;
  final Duration tempo;
  final VoidCallback aoComecar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final total = distribuicaoDaProva.values.fold(0, (s, n) => s + n);
    Widget regra(IconData icone, String texto) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, size: 20, color: esquema.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(texto, style: const TextStyle(fontSize: 15.5, height: 1.45))),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Simulado da prova objetiva'),
        actions: const [BotaoTema()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            regra(Icons.format_list_numbered, '$questoes questões de múltipla escolha, sorteadas na proporção de cada matéria no edital.'),
            regra(Icons.timer_outlined, '${duracaoLegivel(tempo)} de prova, em contagem regressiva. Ao zerar, o simulado é entregue sozinho.'),
            regra(Icons.block, 'Sem dica, sem consulta e sem correção durante a prova, como no dia (edital, item 11.9).'),
            regra(Icons.flag_outlined, 'Corte: 60 pontos em 100. Questão em branco vale zero.'),
            regra(Icons.insights_outlined, 'No fim: nota, desempenho por matéria, assuntos a reforçar e revisão de cada questão.'),
            if (questoes < total)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Cores.de(context).dicaSuave,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Cores.de(context).dica),
                ),
                child: Text(
                  'O banco ainda não tem questões para as $total da prova. Este simulado terá $questoes, com o tempo proporcional (3 minutos por questão, como na prova).',
                  style: TextStyle(fontSize: 14, color: Cores.de(context).dicaTexto),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('comecar-simulado'),
              onPressed: questoes == 0 ? null : aoComecar,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Começar a prova', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlternativaSimulado extends StatelessWidget {
  const _AlternativaSimulado({required this.letra, required this.texto, required this.marcada, required this.aoTocar});

  final String letra;
  final String texto;
  final bool marcada;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: marcada,
      label: 'Alternativa $letra',
      child: Material(
        key: Key('alternativa-$letra'),
        color: marcada ? esquema.primaryContainer : esquema.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: marcada ? esquema.primary : esquema.outline, width: marcada ? 2 : 1.5),
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
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: marcada ? esquema.primary : esquema.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: marcada ? esquema.primary : esquema.outline, width: 1.5),
                  ),
                  child: Text(
                    letra,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: marcada ? esquema.onPrimary : esquema.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(texto, style: Theme.of(context).textTheme.bodyLarge)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultadoSimulado extends StatelessWidget {
  const _ResultadoSimulado({required this.resultado, required this.questoes, required this.unidades});

  final ResultadoSimulado resultado;
  final List<Questao> questoes;
  final List<Unidade> unidades;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final cores = Cores.de(context);
    final passou = resultado.nota >= notaDeCorte;
    final titulo = TextStyle(fontFamily: fonteTitulo, fontSize: 21, fontWeight: FontWeight.w600, color: esquema.onSurface);

    // Por matéria, na ordem da prova.
    final porMateria = <String, (int, int)>{};
    for (final r in resultado.respostas) {
      final (a, t) = porMateria[r.materia] ?? (0, 0);
      porMateria[r.materia] = (a + (r.acertou ? 1 : 0), t + 1);
    }
    final reforcar = errosPorAssunto(
      unidades,
      resultado.respostas.where((r) => !r.acertou).map((r) => r.questaoId),
    ).take(5);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
        title: const Text('Resultado do simulado'),
        actions: const [BotaoTema()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: passou ? cores.acertoSuave : cores.erroSuave,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: passou ? cores.acerto : cores.erro, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${resultado.nota.toStringAsFixed(0)} pontos',
                    key: const Key('nota-simulado'),
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600, color: passou ? cores.acertoTexto : cores.erroTexto),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    passou ? 'Acima do corte de 60 pontos.' : 'Abaixo do corte de 60 pontos.',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: passou ? cores.acertoTexto : cores.erroTexto),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${resultado.acertos} de ${resultado.total} certas · ${resultado.emBranco} em branco · '
                    '${duracaoLegivel(resultado.duracao)} de ${duracaoLegivel(resultado.tempoPrevisto)}',
                    style: TextStyle(fontSize: 14, color: passou ? cores.acertoTexto : cores.erroTexto),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Por matéria', style: titulo),
            const SizedBox(height: 8),
            for (final e in porMateria.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(nomesDasMaterias[e.key] ?? e.key, style: const TextStyle(fontSize: 15))),
                    Text(
                      '${e.value.$1} de ${e.value.$2} · ${porcento(e.value.$1 / e.value.$2)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            if (reforcar.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Onde reforçar', style: titulo),
              const SizedBox(height: 8),
              for (final (u, erros) in reforcar)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (nomesDasMaterias[u.materia] ?? u.materia).toUpperCase(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: esquema.primary),
                      ),
                      Text('${u.titulo} · $erros ${erros == 1 ? 'erro' : 'erros'}', style: TextStyle(fontSize: 15, color: cores.erroTexto)),
                    ],
                  ),
                ),
              Text(
                'Esses erros já estão no seu caderno de erros, na tela de desempenho.',
                style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 24),
            Text('Revisão das questões', style: titulo),
            const SizedBox(height: 4),
            for (var i = 0; i < questoes.length; i++) _LinhaRevisao(numero: i + 1, questao: questoes[i], resposta: resultado.respostas[i]),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('voltar-inicio'),
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinhaRevisao extends StatelessWidget {
  const _LinhaRevisao({required this.numero, required this.questao, required this.resposta});

  final int numero;
  final Questao questao;
  final Resposta resposta;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final esquema = Theme.of(context).colorScheme;
    final branco = resposta.escolhida == semResposta;
    return ListTile(
      key: Key('revisao-$numero'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        resposta.acertou ? Icons.check_circle : Icons.cancel,
        color: resposta.acertou ? cores.acerto : cores.erro,
        semanticLabel: resposta.acertou ? 'certa' : 'errada',
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
