import 'banco.dart';

/// Onde a Flávia está bem e onde precisa reforçar, calculado a partir da
/// última resposta de cada questão (trilha e simulado).
///
/// O "tema" aqui é o assunto do edital (a unidade do banco, ex.: "Licitações e
/// contratos administrativos"). O tema de cada questão é detalhado demais para
/// agrupar: cada questão teria o seu, e o ranking viraria uma lista de uma
/// questão por linha.
class DesempenhoTema {
  DesempenhoTema({required this.unidade});

  final Unidade unidade;
  int feitas = 0;
  int acertos = 0;
  final erradas = <Questao>[];

  int get erros => feitas - acertos;
  double get taxa => feitas == 0 ? 0 : acertos / feitas;
  String get nome => unidade.titulo;
  String get materia => unidade.materia;
}

class DesempenhoMateria {
  DesempenhoMateria({required this.codigo, required this.temas});

  final String codigo;
  final List<DesempenhoTema> temas;

  String get nome => nomesDasMaterias[codigo] ?? codigo;
  int get total => temas.fold(0, (s, t) => s + t.unidade.questoes.length);
  int get feitas => temas.fold(0, (s, t) => s + t.feitas);
  int get acertos => temas.fold(0, (s, t) => s + t.acertos);
  double get taxa => feitas == 0 ? 0 : acertos / feitas;
  List<Questao> get erradas => [for (final t in temas) ...t.erradas];
}

class Desempenho {
  Desempenho(this.materias);

  final List<DesempenhoMateria> materias;

  int get feitas => materias.fold(0, (s, m) => s + m.feitas);
  int get acertos => materias.fold(0, (s, m) => s + m.acertos);
  double get taxa => feitas == 0 ? 0 : acertos / feitas;

  /// Os assuntos que mais precisam de estudo: mais erros primeiro; no empate,
  /// a menor taxa de acerto. Só entra quem tem pelo menos um erro.
  List<DesempenhoTema> get temasAReforcar {
    final comErro = [
      for (final m in materias)
        for (final t in m.temas)
          if (t.erros > 0) t,
    ];
    comErro.sort((a, b) {
      final porErros = b.erros.compareTo(a.erros);
      return porErros != 0 ? porErros : a.taxa.compareTo(b.taxa);
    });
    return comErro;
  }
}

/// [unidades] na ordem do edital; [ultimas] = última resposta de cada questão.
Desempenho analisarDesempenho(List<Unidade> unidades, Map<String, bool> ultimas) {
  final porMateria = <String, List<DesempenhoTema>>{};
  for (final u in unidades) {
    if (u.questoes.isEmpty) continue;
    final tema = DesempenhoTema(unidade: u);
    for (final q in u.questoes) {
      final acertou = ultimas[q.id];
      if (acertou == null) continue;
      tema.feitas++;
      if (acertou) {
        tema.acertos++;
      } else {
        tema.erradas.add(q);
      }
    }
    porMateria.putIfAbsent(u.materia, () => []).add(tema);
  }
  return Desempenho([
    for (final e in porMateria.entries) DesempenhoMateria(codigo: e.key, temas: e.value),
  ]);
}

/// Erros de um conjunto de respostas (ex.: um simulado), agrupados por assunto,
/// do assunto com mais erros para o com menos.
List<(Unidade, int)> errosPorAssunto(List<Unidade> unidades, Iterable<String> idsErrados) {
  final erradas = idsErrados.toSet();
  final contagem = <(Unidade, int)>[
    for (final u in unidades)
      (u, u.questoes.where((q) => erradas.contains(q.id)).length),
  ].where((e) => e.$2 > 0).toList();
  contagem.sort((a, b) => b.$2.compareTo(a.$2));
  return contagem;
}
