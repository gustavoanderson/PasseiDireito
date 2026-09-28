import 'package:flutter/material.dart';

import 'banco.dart';
import 'tela_questao.dart';
import 'tema.dart';

/// As trilhas: uma lista por matéria, com as unidades na ordem do edital.
class TelaInicio extends StatefulWidget {
  const TelaInicio({super.key, this.carregar = carregarUnidades});

  /// Trocável nos testes, para não depender do banco real.
  final Future<List<Unidade>> Function() carregar;

  @override
  State<TelaInicio> createState() => _TelaInicioState();
}

class _TelaInicioState extends State<TelaInicio> {
  late final Future<List<Unidade>> _unidades = widget.carregar();

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<Unidade>>(
          future: _unidades,
          builder: (context, estado) {
            if (estado.hasError) {
              return Center(child: Text('Não consegui abrir o banco de questões.\n${estado.error}'));
            }
            if (!estado.hasData) return const Center(child: CircularProgressIndicator());

            final porMateria = <String, List<Unidade>>{};
            for (final u in estado.data!) {
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
                for (final entrada in porMateria.entries) ...[
                  const SizedBox(height: 24),
                  Text(
                    nomesDasMaterias[entrada.key]!.toUpperCase(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.7, color: esquema.primary),
                  ),
                  const SizedBox(height: 8),
                  for (final u in entrada.value) ...[
                    _CartaoUnidade(unidade: u),
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

class _CartaoUnidade extends StatelessWidget {
  const _CartaoUnidade({required this.unidade});

  final Unidade unidade;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
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
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TelaQuestao(unidade: unidade)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(unidade.titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        'Item ${unidade.itemEdital} do edital · ${unidade.questoes.length} questões',
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
      ),
    );
  }
}
