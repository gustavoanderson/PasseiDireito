import 'package:flutter/material.dart';

import 'banco.dart';
import 'progresso.dart';
import 'tela_questao.dart';
import 'tema.dart';

/// As trilhas: uma lista por matéria, com as unidades na ordem do edital e o
/// andamento de cada uma.
class TelaInicio extends StatefulWidget {
  const TelaInicio({
    super.key,
    required this.registro,
    this.carregar = carregarUnidades,
    this.progressoSalvo = true,
  });

  final RegistroDeProgresso registro;

  /// Trocável nos testes, para não depender do banco real.
  final Future<List<Unidade>> Function() carregar;

  /// Falso quando o Firebase não está configurado: a tela avisa que nada será guardado.
  final bool progressoSalvo;

  @override
  State<TelaInicio> createState() => _TelaInicioState();
}

class _TelaInicioState extends State<TelaInicio> {
  late final Future<List<Unidade>> _unidades = widget.carregar();
  late Future<Map<String, ResumoUnidade>> _resumos = widget.registro.resumos();

  Future<void> _abrir(Unidade unidade) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TelaQuestao(unidade: unidade, registro: widget.registro)),
    );
    // Na volta, o andamento tem que refletir o que ela acabou de fazer.
    // Progresso que não aparece parece progresso perdido (lição do DevLingo).
    if (mounted) setState(() => _resumos = widget.registro.resumos());
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: Future.wait([_unidades, _resumos]),
          builder: (context, estado) {
            if (estado.hasError) {
              return Center(child: Text('Não consegui abrir as trilhas.\n${estado.error}'));
            }
            if (!estado.hasData) return const Center(child: CircularProgressIndicator());

            final unidades = estado.data![0] as List<Unidade>;
            final resumos = estado.data![1] as Map<String, ResumoUnidade>;
            final porMateria = <String, List<Unidade>>{};
            for (final u in unidades) {
              porMateria.putIfAbsent(u.materia, () => []).add(u);
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'PasseiDireito',
                        style: TextStyle(fontFamily: fonteTitulo, fontSize: 26, fontWeight: FontWeight.w600, color: esquema.onSurface),
                      ),
                    ),
                    const BotaoTema(),
                  ],
                ),
                Text(
                  'Procurador do Município de Curitiba · Edital 6/2026',
                  style: TextStyle(fontSize: 14, color: esquema.onSurfaceVariant),
                ),
                if (!widget.progressoSalvo) ...[
                  const SizedBox(height: 16),
                  const _AvisoSemSalvar(),
                ],
                for (final entrada in porMateria.entries) ...[
                  const SizedBox(height: 24),
                  Text(
                    nomesDasMaterias[entrada.key]!.toUpperCase(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.7, color: esquema.primary),
                  ),
                  const SizedBox(height: 8),
                  for (final u in entrada.value) ...[
                    _CartaoUnidade(unidade: u, resumo: resumos[u.id], aoTocar: () => _abrir(u)),
                    const SizedBox(height: 10),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AvisoSemSalvar extends StatelessWidget {
  const _AvisoSemSalvar();

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return Container(
      key: const Key('aviso-sem-salvar'),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cores.dicaSuave,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cores.dica),
      ),
      child: Text(
        'Modo de demonstração: o progresso não está sendo salvo. Fechar o app apaga as respostas.',
        style: TextStyle(fontSize: 14, color: cores.dicaTexto),
      ),
    );
  }
}

class _CartaoUnidade extends StatelessWidget {
  const _CartaoUnidade({required this.unidade, required this.resumo, required this.aoTocar});

  final Unidade unidade;
  final ResumoUnidade? resumo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final total = unidade.questoes.length;
    // Conta só questões que ainda existem na unidade: id aposentado não infla o número.
    final ids = {for (final q in unidade.questoes) q.id};
    final feitas = resumo?.ultimaPorQuestao.keys.where(ids.contains).length ?? 0;
    final acertos = resumo?.ultimaPorQuestao.entries.where((e) => ids.contains(e.key) && e.value).length ?? 0;
    final andamento = feitas == 0
        ? 'Item ${unidade.itemEdital} do edital · $total questões'
        : '$feitas de $total feitas · $acertos acertos';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        key: Key('unidade-${unidade.id}'),
        color: esquema.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: esquema.outline, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(unidade.titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(andamento, style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: esquema.onSurfaceVariant),
                  ],
                ),
                if (feitas > 0 && total > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: feitas / total,
                      minHeight: 6,
                      color: esquema.primary,
                      backgroundColor: esquema.outline.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
