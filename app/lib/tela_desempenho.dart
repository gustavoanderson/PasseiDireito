import 'package:flutter/material.dart';

import 'banco.dart';
import 'desempenho.dart';
import 'progresso.dart';
import 'tela_questao.dart';
import 'tema.dart';

String porcento(double taxa) => '${(taxa * 100).round()}%';

String dataCurta(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Estatísticas e caderno de erros: onde a Flávia acerta, onde erra e o que
/// rever. Recebe tudo já carregado, para ser testável sem rede.
class TelaDesempenho extends StatelessWidget {
  const TelaDesempenho({
    super.key,
    required this.unidades,
    required this.ultimas,
    required this.simulados,
    required this.registro,
  });

  final List<Unidade> unidades;
  final Map<String, bool> ultimas;
  final List<ResultadoSimulado> simulados;
  final RegistroDeProgresso registro;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final d = analisarDesempenho(unidades, ultimas);
    final reforcar = d.temasAReforcar.take(5).toList();
    final comErros = d.materias.where((m) => m.erradas.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Seu desempenho'),
        actions: const [BotaoTema()],
      ),
      body: SafeArea(
        child: d.feitas == 0 && simulados.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Responda questões nas trilhas ou faça um simulado. Aqui aparece onde você está bem e o que precisa reforçar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: esquema.onSurfaceVariant),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _Resumo(desempenho: d),
                  if (reforcar.isNotEmpty) ...[
                    const _Secao('Onde reforçar'),
                    Text(
                      'Assuntos com mais erros na sua última tentativa de cada questão.',
                      style: TextStyle(fontSize: 14, color: esquema.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    for (final t in reforcar) _LinhaTema(tema: t, mostrarMateria: true),
                  ],
                  if (simulados.isNotEmpty) ...[
                    const _Secao('Simulados'),
                    for (final s in simulados) _LinhaSimulado(simulado: s),
                  ],
                  if (d.feitas > 0) ...[
                    const _Secao('Por matéria'),
                    for (final m in d.materias.where((m) => m.feitas > 0)) _BlocoMateria(materia: m),
                  ],
                  if (comErros.isNotEmpty) ...[
                    const _Secao('Caderno de erros'),
                    for (final m in comErros) _CadernoDaMateria(materia: m, registro: registro),
                  ],
                ],
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
      padding: const EdgeInsets.only(top: 28, bottom: 8),
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

class _Resumo extends StatelessWidget {
  const _Resumo({required this.desempenho});

  final Desempenho desempenho;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: esquema.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: esquema.outline),
      ),
      child: Row(
        children: [
          Text(
            porcento(desempenho.taxa),
            key: const Key('taxa-geral'),
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w600, color: esquema.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'de acerto em ${desempenho.feitas} ${desempenho.feitas == 1 ? 'questão respondida' : 'questões respondidas'}',
              style: TextStyle(fontSize: 15, color: esquema.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra(this.valor);

  final double valor;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: valor,
        minHeight: 6,
        color: esquema.primary,
        backgroundColor: esquema.outline.withValues(alpha: 0.5),
      ),
    );
  }
}

class _LinhaTema extends StatelessWidget {
  const _LinhaTema({required this.tema, this.mostrarMateria = false});

  final DesempenhoTema tema;
  final bool mostrarMateria;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final cores = Cores.de(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mostrarMateria)
            Text(
              (nomesDasMaterias[tema.materia] ?? tema.materia).toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: esquema.primary),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(tema.nome, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
              const SizedBox(width: 12),
              Text(porcento(tema.taxa), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: esquema.onSurface)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            tema.erros == 0
                ? '${tema.feitas} feitas, nenhum erro'
                : '${tema.erros} ${tema.erros == 1 ? 'erro' : 'erros'} em ${tema.feitas} feitas',
            style: TextStyle(fontSize: 13, color: tema.erros == 0 ? esquema.onSurfaceVariant : cores.erroTexto),
          ),
          const SizedBox(height: 6),
          _Barra(tema.taxa),
        ],
      ),
    );
  }
}

class _LinhaSimulado extends StatelessWidget {
  const _LinhaSimulado({required this.simulado});

  final ResultadoSimulado simulado;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final cores = Cores.de(context);
    final passou = simulado.nota >= notaDeCorte;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(passou ? Icons.check_circle_outline : Icons.error_outline, color: passou ? cores.acerto : cores.erro),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${dataCurta(simulado.inicio)} · ${simulado.acertos} de ${simulado.total}',
              style: const TextStyle(fontSize: 15),
            ),
          ),
          Text(
            '${simulado.nota.toStringAsFixed(0)} pts',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: esquema.onSurface),
          ),
        ],
      ),
    );
  }
}

class _BlocoMateria extends StatelessWidget {
  const _BlocoMateria({required this.materia});

  final DesempenhoMateria materia;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: Key('bloco-${materia.codigo}'),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 4),
        title: Text(materia.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${porcento(materia.taxa)} de acerto · ${materia.feitas} de ${materia.total} feitas',
          style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant),
        ),
        children: [for (final t in materia.temas.where((t) => t.feitas > 0)) _LinhaTema(tema: t)],
      ),
    );
  }
}

class _CadernoDaMateria extends StatelessWidget {
  const _CadernoDaMateria({required this.materia, required this.registro});

  final DesempenhoMateria materia;
  final RegistroDeProgresso registro;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final erradas = materia.erradas;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${materia.nome} · ${erradas.length} para rever',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              FilledButton.tonal(
                key: Key('refazer-${materia.codigo}'),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => TelaQuestao(
                    nomeDaMateria: materia.nome,
                    questoes: erradas.take(10).toList(),
                    registro: registro,
                  ),
                )),
                child: const Text('Refazer'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final q in erradas)
            ListTile(
              key: Key('erro-${q.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(q.tema, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: Text(
                q.enunciado,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant),
              ),
              trailing: Icon(Icons.chevron_right, color: esquema.onSurfaceVariant),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => TelaRevisaoQuestao(questao: q, nomeDaMateria: materia.nome),
              )),
            ),
        ],
      ),
    );
  }
}
