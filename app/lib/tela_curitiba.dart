import 'package:flutter/material.dart';

import 'banco.dart';
import 'progresso.dart';
import 'tela_questao.dart';
import 'tema.dart';
import 'trilha.dart';

/// Praticar só a legislação municipal de Curitiba, matéria por matéria —
/// pedido da Flávia em 20/10/2026: hoje Direito Administrativo (e outras
/// matérias) misturam lei geral com lei municipal, e ela quer poder treinar
/// só a parte de Curitiba, já que é a prefeitura onde ela vai prestar.
class TelaCuritiba extends StatefulWidget {
  const TelaCuritiba({super.key, required this.unidades, required this.registro});

  final List<Unidade> unidades;
  final RegistroDeProgresso registro;

  @override
  State<TelaCuritiba> createState() => _TelaCuritibaState();
}

class _TelaCuritibaState extends State<TelaCuritiba> {
  late Future<Map<String, ResumoUnidade>> _resumos = widget.registro.resumos();

  void _recarregar() {
    if (!mounted) return;
    setState(() {
      _resumos = widget.registro.resumos();
    });
  }

  Future<void> _praticar(Materia materia, Map<String, bool> ultimas) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TelaQuestao(
        nomeDaMateria: '${materia.nome} · Curitiba',
        questoes: montarSessao(materia.questoes, ultimas),
        registro: widget.registro,
      ),
    ));
    _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final materias = materiasDeLegislacaoCuritiba(widget.unidades);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Legislação de Curitiba'),
        actions: const [BotaoTema()],
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: _resumos,
          builder: (context, estado) {
            if (estado.hasError) {
              return Center(child: Text('Não consegui abrir a legislação de Curitiba.\n${estado.error}'));
            }
            if (!estado.hasData) return const Center(child: CircularProgressIndicator());
            final ultimas = ultimasRespostas(estado.data!);

            if (materias.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Ainda não há questões marcadas como legislação de Curitiba no banco.',
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
                  'Só as questões que citam lei ou decreto do Município de Curitiba, separadas da legislação geral de cada matéria.',
                  style: TextStyle(fontSize: 14, color: esquema.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                for (final m in materias) ...[
                  _CartaoMateriaCuritiba(
                    materia: m,
                    ultimas: ultimas,
                    aoTocar: () => _praticar(m, ultimas),
                  ),
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

class _CartaoMateriaCuritiba extends StatelessWidget {
  const _CartaoMateriaCuritiba({required this.materia, required this.ultimas, required this.aoTocar});

  final Materia materia;
  final Map<String, bool> ultimas;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final total = materia.questoes.length;
    final respondidas = [for (final q in materia.questoes) if (ultimas.containsKey(q.id)) ultimas[q.id]!];
    final feitas = respondidas.length;
    final acertos = respondidas.where((a) => a).length;
    final andamento = feitas == 0 ? (total == 1 ? '1 questão' : '$total questões') : '$feitas de $total feitas · $acertos acertos';

    return Material(
      key: Key('curitiba-${materia.codigo}'),
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(materia.nome, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(andamento, style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant)),
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
