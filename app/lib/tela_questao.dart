import 'package:flutter/material.dart';

import 'banco.dart';
import 'progresso.dart';
import 'tema.dart';

/// Uma sessão da trilha de uma matéria, questão por questão.
///
/// Regras combinadas com o Gustavo (CLAUDE.md): uma tentativa, correção
/// imediata com a explicação de todas as alternativas, dica disponível antes
/// de confirmar, e a aluna segue na trilha mesmo errando.
class TelaQuestao extends StatefulWidget {
  const TelaQuestao({super.key, required this.nomeDaMateria, required this.questoes, required this.registro});

  final String nomeDaMateria;
  final List<Questao> questoes;
  final RegistroDeProgresso registro;

  @override
  State<TelaQuestao> createState() => _TelaQuestaoState();
}

class _TelaQuestaoState extends State<TelaQuestao> {
  int _indice = 0;
  String? _escolhida;
  bool _confirmada = false;
  bool _dicaAberta = false;
  // Abrir a dica e fechar de novo ainda conta como ter usado.
  bool _dicaUsada = false;
  int _acertos = 0;
  bool _terminou = false;
  final _rolagem = ScrollController();

  Questao get _questao => widget.questoes[_indice];
  bool get _acertou => _confirmada && _escolhida == _questao.correta;

  @override
  void dispose() {
    _rolagem.dispose();
    super.dispose();
  }

  void _escolher(String letra) {
    // Uma tentativa só: depois de confirmar, a escolha não muda.
    if (_confirmada) return;
    setState(() => _escolhida = letra);
  }

  void _confirmar() {
    final acertou = _escolhida == _questao.correta;
    setState(() {
      _confirmada = true;
      _dicaAberta = false;
      if (acertou) _acertos++;
    });
    // Salvo a cada questão: fechar o app no meio da sessão não perde nada.
    widget.registro.registrar(Resposta(
      questaoId: _questao.id,
      unidadeId: _questao.unidadeId,
      materia: _questao.materia,
      escolhida: _escolhida!,
      acertou: acertou,
      usouDica: _dicaUsada,
      em: DateTime.now(),
    ));
  }

  void _continuar() {
    final ultima = _indice == widget.questoes.length - 1;
    if (ultima) {
      // O placar é parte desta tela, e não uma rota que a substitui: assim
      // "Voltar às matérias" fecha a trilha, e quem a abriu sabe quando
      // recarregar o andamento.
      setState(() => _terminou = true);
      return;
    }
    setState(() {
      _indice++;
      _escolhida = null;
      _confirmada = false;
      _dicaAberta = false;
      _dicaUsada = false;
    });
    _rolagem.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_terminou) {
      return TelaFimSessao(nomeDaMateria: widget.nomeDaMateria, total: widget.questoes.length, acertos: _acertos);
    }
    final q = _questao;
    final esquema = Theme.of(context).colorScheme;
    final total = widget.questoes.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Sair da trilha',
                    icon: const Icon(Icons.close),
                    color: esquema.onSurfaceVariant,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Semantics(
                      label: 'Questão ${_indice + 1} de $total',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_indice + (_confirmada ? 1 : 0)) / total,
                          minHeight: 8,
                          color: esquema.primary,
                          backgroundColor: esquema.outline.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  const BotaoTema(),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _rolagem,
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Etiqueta(widget.nomeDaMateria),
                      Text(q.tema, style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(q.enunciado, style: Theme.of(context).textTheme.titleLarge),
                  if (_dicaAberta && !_confirmada) ...[
                    const SizedBox(height: 16),
                    _CaixaDica(q.dica),
                  ],
                  const SizedBox(height: 16),
                  for (final letra in letras) ...[
                    _Alternativa(
                      letra: letra,
                      texto: q.alternativas[letra]!,
                      estado: _estadoDe(letra),
                      aoTocar: () => _escolher(letra),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_confirmada) ...[
                    const SizedBox(height: 6),
                    _Explicacao(questao: q),
                  ],
                ],
              ),
            ),
            if (_confirmada)
              _RodapeResultado(acertou: _acertou, correta: q.correta, aoContinuar: _continuar)
            else
              _RodapePergunta(
                dicaAberta: _dicaAberta,
                podeConfirmar: _escolhida != null,
                aoAlternarDica: () => setState(() {
                  _dicaAberta = !_dicaAberta;
                  _dicaUsada = true;
                }),
                aoConfirmar: _confirmar,
              ),
          ],
        ),
      ),
    );
  }

  _EstadoAlternativa _estadoDe(String letra) {
    final escolhida = letra == _escolhida;
    if (!_confirmada) return escolhida ? _EstadoAlternativa.selecionada : _EstadoAlternativa.normal;
    if (letra == _questao.correta) {
      return escolhida ? _EstadoAlternativa.acertou : _EstadoAlternativa.correta;
    }
    return escolhida ? _EstadoAlternativa.errou : _EstadoAlternativa.apagada;
  }
}

enum _EstadoAlternativa { normal, selecionada, acertou, correta, errou, apagada }

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: esquema.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
          color: esquema.primary,
        ),
      ),
    );
  }
}

class _Alternativa extends StatelessWidget {
  const _Alternativa({
    required this.letra,
    required this.texto,
    required this.estado,
    required this.aoTocar,
  });

  final String letra;
  final String texto;
  final _EstadoAlternativa estado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final cores = Cores.de(context);

    // borda, fundo, texto, fundo do selo, conteúdo do selo
    final (borda, fundo, corTexto, seloFundo, seloConteudo) = switch (estado) {
      _EstadoAlternativa.normal => (esquema.outline, esquema.surface, esquema.onSurface, esquema.surface, esquema.onSurfaceVariant),
      _EstadoAlternativa.selecionada => (esquema.primary, esquema.primaryContainer, esquema.onSurface, esquema.primary, esquema.onPrimary),
      _EstadoAlternativa.acertou || _EstadoAlternativa.correta => (cores.acerto, cores.acertoSuave, esquema.onSurface, cores.acerto, cores.sobreSelo),
      _EstadoAlternativa.errou => (cores.erro, cores.erroSuave, esquema.onSurface, cores.erro, cores.sobreSelo),
      _EstadoAlternativa.apagada => (esquema.outline, esquema.surface, esquema.onSurfaceVariant, esquema.surface, esquema.onSurfaceVariant),
    };
    final destacada = estado != _EstadoAlternativa.normal && estado != _EstadoAlternativa.apagada;

    // A cor nunca fala sozinha: acerto e erro também têm ícone e rótulo.
    final rotulo = switch (estado) {
      _EstadoAlternativa.acertou => 'Sua resposta · correta',
      _EstadoAlternativa.correta => 'Resposta correta',
      _EstadoAlternativa.errou => 'Sua resposta',
      _ => null,
    };
    final corRotulo = estado == _EstadoAlternativa.errou ? cores.erroTexto : cores.acertoTexto;

    final Widget conteudoSelo = switch (estado) {
      _EstadoAlternativa.acertou || _EstadoAlternativa.correta => Icon(Icons.check, size: 17, color: seloConteudo),
      _EstadoAlternativa.errou => Icon(Icons.close, size: 16, color: seloConteudo),
      _ => Text(letra, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: seloConteudo)),
    };

    return Semantics(
      button: true,
      selected: estado == _EstadoAlternativa.selecionada,
      label: 'Alternativa $letra${rotulo != null ? ', $rotulo' : ''}',
      excludeSemantics: false,
      child: Material(
        key: Key('alternativa-$letra'),
        color: fundo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borda, width: destacada ? 2 : 1.5),
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
                    color: seloFundo,
                    shape: BoxShape.circle,
                    border: Border.all(color: borda == esquema.outline ? esquema.outline : seloFundo, width: 1.5),
                  ),
                  child: conteudoSelo,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (rotulo != null) ...[
                        Text(
                          rotulo.toUpperCase(),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: corRotulo),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(texto, style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: corTexto)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaixaDica extends StatelessWidget {
  const _CaixaDica(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return Container(
      key: const Key('caixa-dica'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cores.dicaSuave,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cores.dica, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: cores.dicaTexto),
              const SizedBox(width: 8),
              Text('Dica', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: cores.dicaTexto)),
            ],
          ),
          const SizedBox(height: 8),
          Text(texto, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: cores.dicaTexto)),
        ],
      ),
    );
  }
}

class _Explicacao extends StatelessWidget {
  const _Explicacao({required this.questao});

  final Questao questao;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final cores = Cores.de(context);
    final titulo = TextStyle(fontFamily: fonteTitulo, fontSize: 18, fontWeight: FontWeight.w600, color: esquema.onSurface);
    final corpo = Theme.of(context).textTheme.bodyMedium;
    final erradas = letras.where((l) => l != questao.correta);

    return Container(
      key: const Key('explicacao'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: esquema.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: esquema.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Por que a ${questao.correta} está correta', style: titulo),
          const SizedBox(height: 10),
          Text(questao.explicacao[questao.correta]!, style: corpo),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final f in questao.fontes)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: esquema.primaryContainer, borderRadius: BorderRadius.circular(6)),
                  child: Text(f.referencia, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: esquema.primary)),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: esquema.outline),
          ),
          Text('Por que as outras estão erradas', style: titulo),
          const SizedBox(height: 10),
          for (final l in erradas) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cores.erroSuave,
                    shape: BoxShape.circle,
                    border: Border.all(color: cores.erro),
                  ),
                  child: Text(l, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cores.erroTexto)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(questao.explicacao[l]!, style: corpo)),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

const _alturaBotao = 48.0;

class _RodapePergunta extends StatelessWidget {
  const _RodapePergunta({
    required this.dicaAberta,
    required this.podeConfirmar,
    required this.aoAlternarDica,
    required this.aoConfirmar,
  });

  final bool dicaAberta;
  final bool podeConfirmar;
  final VoidCallback aoAlternarDica;
  final VoidCallback aoConfirmar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final cores = Cores.de(context);
    final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    const textoBotao = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: fonteTexto);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: esquema.outline))),
      child: Row(
        children: [
          OutlinedButton.icon(
            key: const Key('botao-dica'),
            onPressed: aoAlternarDica,
            icon: const Icon(Icons.lightbulb_outline, size: 18),
            label: Text(dicaAberta ? 'Ocultar' : 'Dica'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, _alturaBotao),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              backgroundColor: cores.dicaSuave,
              foregroundColor: cores.dicaTexto,
              side: BorderSide(color: cores.dica, width: 1.5),
              shape: forma,
              textStyle: textoBotao,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              key: const Key('botao-confirmar'),
              onPressed: podeConfirmar ? aoConfirmar : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, _alturaBotao),
                backgroundColor: esquema.primary,
                foregroundColor: esquema.onPrimary,
                shape: forma,
                textStyle: textoBotao,
              ),
              child: const Text('Confirmar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RodapeResultado extends StatelessWidget {
  const _RodapeResultado({required this.acertou, required this.correta, required this.aoContinuar});

  final bool acertou;
  final String correta;
  final VoidCallback aoContinuar;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final cor = acertou ? cores.acerto : cores.erro;
    final corTexto = acertou ? cores.acertoTexto : cores.erroTexto;

    return Container(
      key: const Key('rodape-resultado'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: acertou ? cores.acertoSuave : cores.erroSuave,
        border: Border(top: BorderSide(color: cor, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                child: Icon(acertou ? Icons.check : Icons.close, size: 18, color: cores.sobreSelo),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      acertou ? 'Muito bem!' : 'Resposta incorreta',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: corTexto),
                    ),
                    Text(
                      acertou
                          ? 'Leia a explicação para fixar o fundamento.'
                          : 'A correta é a $correta. Veja a explicação acima.',
                      style: TextStyle(fontSize: 14, color: corTexto),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton(
            key: const Key('botao-continuar'),
            onPressed: aoContinuar,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, _alturaBotao),
              backgroundColor: cor,
              foregroundColor: cores.sobreSelo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: fonteTexto),
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}

class TelaFimSessao extends StatelessWidget {
  const TelaFimSessao({super.key, required this.nomeDaMateria, required this.total, required this.acertos});

  final String nomeDaMateria;
  final int total;
  final int acertos;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'Sessão concluída',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: fonteTitulo, fontSize: 28, fontWeight: FontWeight.w600, color: esquema.onSurface),
              ),
              const SizedBox(height: 8),
              Text(nomeDaMateria, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: esquema.onSurfaceVariant)),
              const SizedBox(height: 32),
              Text(
                '$acertos de $total',
                key: const Key('placar'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 44, fontWeight: FontWeight.w600, color: esquema.primary),
              ),
              Text('acertos', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: esquema.onSurfaceVariant)),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, _alturaBotao),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Voltar às matérias'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
