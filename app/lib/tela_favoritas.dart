import 'package:flutter/material.dart';

import 'banco.dart';
import 'favoritos.dart';
import 'progresso.dart';
import 'tela_questao.dart';
import 'tema.dart';

/// Lista das questões marcadas com a estrela, pra reler a explicação quando
/// quiser — pedido da Flávia em 14/10/2026: ela quer poder voltar numa
/// questão que já fez, acertando ou errando, sem depender do caderno de
/// erros (que só guarda as erradas).
class TelaFavoritas extends StatefulWidget {
  const TelaFavoritas({super.key, required this.unidades, required this.registro});

  final List<Unidade> unidades;
  final RegistroDeProgresso registro;

  @override
  State<TelaFavoritas> createState() => _TelaFavoritasState();
}

class _TelaFavoritasState extends State<TelaFavoritas> {
  late Future<List<String>> _ids = widget.registro.favoritas();

  /// Desmarcar uma favorita na tela de revisão não atualiza esta lista
  /// sozinho: recarrega ao voltar, mesmo padrão da tela inicial.
  void _recarregar() {
    if (!mounted) return;
    setState(() {
      _ids = widget.registro.favoritas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Questões favoritas'),
        actions: const [BotaoTema()],
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: _ids,
          builder: (context, estado) {
            if (estado.hasError) {
              return Center(child: Text('Não consegui abrir os favoritos.\n${estado.error}'));
            }
            if (!estado.hasData) return const Center(child: CircularProgressIndicator());

            final questoes = questoesFavoritas(widget.unidades, estado.data!);
            if (questoes.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Toque na estrela de uma questão, na trilha ou na revisão, para guardá-la aqui.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: esquema.onSurfaceVariant),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: questoes.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: esquema.outline),
              itemBuilder: (context, i) => _LinhaFavorita(questao: questoes[i], registro: widget.registro, aoVoltar: _recarregar),
            );
          },
        ),
      ),
    );
  }
}

class _LinhaFavorita extends StatelessWidget {
  const _LinhaFavorita({required this.questao, required this.registro, required this.aoVoltar});

  final Questao questao;
  final RegistroDeProgresso registro;
  final VoidCallback aoVoltar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final nomeDaMateria = nomesDasMaterias[questao.materia] ?? questao.materia;
    return ListTile(
      key: Key('favorita-${questao.id}'),
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nomeDaMateria.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: esquema.primary),
          ),
          const SizedBox(height: 2),
          Text(questao.tema, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          questao.enunciado,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant),
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: esquema.onSurfaceVariant),
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TelaRevisaoQuestao(
            questao: questao,
            nomeDaMateria: nomeDaMateria,
            registro: registro,
            favoritaInicial: true,
          ),
        ));
        aoVoltar();
      },
    );
  }
}
