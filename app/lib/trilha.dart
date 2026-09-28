import 'banco.dart';
import 'progresso.dart';

/// A trilha de uma matéria: todas as questões dela, na ordem do edital.
///
/// A Flávia escolhe a matéria e cai direto na pergunta. As unidades existem
/// só nos arquivos do banco; na tela, o tema aparece dentro da questão.
class Materia {
  const Materia({required this.codigo, required this.questoes});

  final String codigo;
  final List<Questao> questoes;

  String get nome => nomesDasMaterias[codigo] ?? codigo;
}

/// Agrupa as unidades (já na ordem do edital) em matérias.
List<Materia> agruparPorMateria(List<Unidade> unidades) {
  final porMateria = <String, List<Questao>>{};
  for (final u in unidades) {
    porMateria.putIfAbsent(u.materia, () => []).addAll(u.questoes);
  }
  return [
    for (final e in porMateria.entries)
      if (e.value.isNotEmpty) Materia(codigo: e.key, questoes: e.value),
  ];
}

/// A última resposta de cada questão, de todas as unidades.
Map<String, bool> ultimasRespostas(Map<String, ResumoUnidade> resumos) => {
      for (final r in resumos.values) ...r.ultimaPorQuestao,
    };

const tamanhoDaSessao = 10;

/// As questões da próxima sessão: primeiro as inéditas, na ordem do edital;
/// depois as que ela errou; por fim, se acertou tudo, as já acertadas, para
/// a trilha nunca ficar sem ter o que oferecer.
List<Questao> montarSessao(
  List<Questao> questoes,
  Map<String, bool> ultimas, {
  int tamanho = tamanhoDaSessao,
}) {
  final ineditas = questoes.where((q) => !ultimas.containsKey(q.id));
  final erradas = questoes.where((q) => ultimas[q.id] == false);
  final acertadas = questoes.where((q) => ultimas[q.id] == true);
  return [...ineditas, ...erradas, ...acertadas].take(tamanho).toList();
}
