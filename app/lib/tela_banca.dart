import 'package:flutter/material.dart';

import 'banca.dart';
import 'banco.dart';
import 'tema.dart';

/// "Raio-X da banca": fora das trilhas, como a Flávia pediu em 08/10/2026.
/// Duas perguntas: (1) quais questões reais da FAFIPA ela já anulou ou teve
/// que corrigir o gabarito, e por quê; (2) o que ela mais cobra por matéria,
/// e que itens do nosso edital não têm registro nenhum na amostra —
/// excluindo a legislação municipal, que não se compara entre cidades.
class TelaBanca extends StatefulWidget {
  const TelaBanca({
    super.key,
    this.carregarHistorico = carregarHistoricoFafipa,
    this.carregarTemas = carregarTemasFafipa,
  });

  /// Trocáveis nos testes, para não depender do asset real.
  final Future<HistoricoFafipa> Function() carregarHistorico;
  final Future<TemasFafipa> Function() carregarTemas;

  @override
  State<TelaBanca> createState() => _TelaBancaState();
}

class _TelaBancaState extends State<TelaBanca> {
  late final Future<(HistoricoFafipa, TemasFafipa)> _dados =
      (widget.carregarHistorico(), widget.carregarTemas()).wait;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Raio-X da banca'),
        actions: const [BotaoTema()],
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: _dados,
          builder: (context, estado) {
            if (estado.hasError) {
              return Center(child: Text('Não consegui abrir a análise.\n${estado.error}'));
            }
            if (!estado.hasData) return const Center(child: CircularProgressIndicator());
            final (historico, temas) = estado.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  'Um diagnóstico da FAFIPA: o que ela mais cobra, o que ainda não apareceu nas provas que a gente conseguiu analisar, e onde ela já errou o próprio gabarito.',
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const _Secao('O que a banca mais cobra'),
                _ResumoPadroes(temas: temas),
                const SizedBox(height: 18),
                for (final c in coberturaPorMateria(temas).where((c) => c.comRegistro + c.semRegistro > 0))
                  _LinhaCobertura(cobertura: c),
                const SizedBox(height: 10),
                for (final entrada in temas.materias.entries)
                  if (entrada.value.notaEspecial != null) _NotaEspecial(materia: entrada.key, texto: entrada.value.notaEspecial!),
                const _Secao('Anulações e correções de gabarito'),
                _ResumoAnulacoes(resumo: historico.resumo),
                const SizedBox(height: 14),
                for (final p in historico.provas.where((p) => p.temAlerta)) _LinhaProva(prova: p, historico: historico),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 10),
      child: Text(
        titulo,
        style: TextStyle(
          fontFamily: fonteTitulo,
          fontSize: 21,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _ResumoPadroes extends StatelessWidget {
  const _ResumoPadroes({required this.temas});

  final TemasFafipa temas;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: esquema.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: esquema.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, padrao) in temas.padroesGerais.indexed) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 6, color: esquema.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(child: Text(padrao, style: const TextStyle(fontSize: 14, height: 1.4))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Barra proporcional: fração dos itens do edital (sem contar os municipais)
/// com registro histórico na amostra x sem registro.
class _LinhaCobertura extends StatelessWidget {
  const _LinhaCobertura({required this.cobertura});

  final CoberturaMateria cobertura;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final cores = Cores.de(context);
    final comparaveis = cobertura.comRegistro + cobertura.semRegistro;
    return Padding(
      key: Key('cobertura-${cobertura.materia}'),
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(cobertura.nome, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
              Text(
                comparaveis == 0
                    ? 'sem item comparável'
                    : '${cobertura.comRegistro} de $comparaveis itens com registro',
                style: TextStyle(fontSize: 12, color: esquema.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 5),
          if (comparaveis > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    if (cobertura.comRegistro > 0) Expanded(flex: cobertura.comRegistro, child: Container(color: cores.acerto)),
                    if (cobertura.semRegistro > 0) Expanded(flex: cobertura.semRegistro, child: Container(color: esquema.outline)),
                  ],
                ),
              ),
            )
          else
            Container(height: 10, decoration: BoxDecoration(color: esquema.outline.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4))),
          if (cobertura.municipais > 0) ...[
            const SizedBox(height: 3),
            Text(
              '+ ${cobertura.municipais} ${cobertura.municipais == 1 ? 'item de legislação municipal' : 'itens de legislação municipal'} (não comparável entre cidades)',
              style: TextStyle(fontSize: 11, color: esquema.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotaEspecial extends StatelessWidget {
  const _NotaEspecial({required this.materia, required this.texto});

  final String materia;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        key: Key('nota-$materia'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cores.dicaSuave, borderRadius: BorderRadius.circular(10)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.priority_high, size: 18, color: cores.dicaTexto),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${nomesDasMaterias[materia] ?? materia}: $texto',
                style: TextStyle(fontSize: 13, height: 1.4, color: cores.dicaTexto),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumoAnulacoes extends StatelessWidget {
  const _ResumoAnulacoes({required this.resumo});

  final ResumoHistorico resumo;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final porcento = (resumo.taxaDeAnulacao * 100).toStringAsFixed(1).replaceAll('.', ',');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: esquema.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: esquema.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$porcento%', key: const Key('taxa-anulacao'), style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: esquema.primary)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'das questões anuladas em ${resumo.provasComGabaritoDefinitivo} provas recentes da FAFIPA para cargos jurídicos (${resumo.questoesNessasProvas} questões, ${resumo.anuladas} anuladas, ${resumo.gabaritosAlterados} gabaritos corrigidos).',
                  style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(resumo.observacao, style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}

class _LinhaProva extends StatelessWidget {
  const _LinhaProva({required this.prova, required this.historico});

  final ProvaFafipa prova;
  final HistoricoFafipa historico;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final cores = Cores.de(context);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: Key('prova-${prova.concurso}-${prova.ano}'),
        tilePadding: EdgeInsets.zero,
        leading: Icon(Icons.priority_high, color: cores.erro),
        title: Text('${prova.concurso} · ${prova.ano}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: Text(
          !prova.gabaritoDefinitivoPublicado
              ? 'Só o gabarito preliminar saiu até agora'
              : '${prova.cargo} · ${prova.anuladas.length} ${prova.anuladas.length == 1 ? 'anulada' : 'anuladas'}'
                  '${prova.gabaritoAlterado.isNotEmpty ? ' · ${prova.gabaritoAlterado.length} gabarito corrigido' : ''}',
          style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (prova.observacao != null) ...[
                  Text(prova.observacao!, style: const TextStyle(fontSize: 13, height: 1.4)),
                  if (prova.anuladas.isNotEmpty || prova.gabaritoAlterado.isNotEmpty) const SizedBox(height: 8),
                ],
                for (final a in prova.anuladas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Questão ${a.numero} anulada'
                      '${historico.descricaoDoMotivo(a.motivo) != null ? ' — ${historico.descricaoDoMotivo(a.motivo)}' : ''}'
                      '${a.observacao != null ? ' (${a.observacao})' : ''}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                for (final g in prova.gabaritoAlterado)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Questão ${g.numero}: gabarito corrigido para ${g.paraLetra}'
                      '${historico.descricaoDoMotivo(g.motivo) != null ? ' — ${historico.descricaoDoMotivo(g.motivo)}' : ''}',
                      style: const TextStyle(fontSize: 13),
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
