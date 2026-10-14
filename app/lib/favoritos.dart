import 'banco.dart';

/// As questões favoritas, na ordem em que foram marcadas (mais recente
/// primeiro). Ids que não existem mais no banco (unidade removida ou
/// renumerada) são ignorados, em vez de quebrar a tela.
List<Questao> questoesFavoritas(List<Unidade> unidades, List<String> ids) {
  final porId = {for (final u in unidades) for (final q in u.questoes) q.id: q};
  return [for (final id in ids) if (porId[id] != null) porId[id]!];
}
