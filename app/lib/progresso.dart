/// O progresso da Flávia: cada resposta dada (na trilha ou no simulado), o
/// resumo por unidade e o histórico de simulados.
///
/// As telas dependem desta interface, nunca do Firestore direto. Assim os
/// testes de tela usam a versão em memória, sem rede e sem relógio real
/// (lição registrada no DevLingo: teste de widget não enxerga I/O real).
library;

enum OrigemResposta { trilha, simulado }

/// Resposta em branco no simulado. Na prova, vale zero, como resposta errada.
const semResposta = '-';

class Resposta {
  const Resposta({
    required this.questaoId,
    required this.unidadeId,
    required this.materia,
    required this.escolhida,
    required this.acertou,
    required this.usouDica,
    required this.em,
    this.origem = OrigemResposta.trilha,
  });

  final String questaoId;
  final String unidadeId;
  final String materia;
  final String escolhida;
  final bool acertou;
  final bool usouDica;
  final DateTime em;
  final OrigemResposta origem;
}

/// Situação de uma unidade: para cada questão já respondida, se a ÚLTIMA
/// resposta foi certa. Refazer a questão substitui o resultado anterior,
/// porque o que interessa é se ela sabe hoje, não se sabia na primeira vez.
class ResumoUnidade {
  const ResumoUnidade(this.ultimaPorQuestao);

  final Map<String, bool> ultimaPorQuestao;

  int get feitas => ultimaPorQuestao.length;
  int get acertos => ultimaPorQuestao.values.where((a) => a).length;
}

/// Um simulado entregue. As respostas também entram no progresso comum, para
/// o erro cometido no simulado aparecer no caderno de erros.
class ResultadoSimulado {
  const ResultadoSimulado({
    required this.inicio,
    required this.duracao,
    required this.tempoPrevisto,
    required this.respostas,
  });

  final DateTime inicio;
  final Duration duracao;
  final Duration tempoPrevisto;

  /// Na ordem em que as questões apareceram na prova.
  final List<Resposta> respostas;

  int get total => respostas.length;
  int get acertos => respostas.where((r) => r.acertou).length;
  int get emBranco => respostas.where((r) => r.escolhida == semResposta).length;

  /// Nota de 0 a 100, a mesma escala do edital (item 11.25).
  double get nota => total == 0 ? 0 : 100 * acertos / total;
}

/// O corte da prova objetiva: 60 pontos em 100 (edital, item 11.25).
const notaDeCorte = 60.0;

abstract interface class RegistroDeProgresso {
  /// Grava uma resposta. Deve voltar rápido mesmo sem internet: a trilha não
  /// pode travar no "Continuar" esperando o servidor.
  Future<void> registrar(Resposta resposta);

  /// Resumo de todas as unidades já iniciadas, pelo id da unidade.
  Future<Map<String, ResumoUnidade>> resumos();

  /// Grava o simulado entregue e cada uma das suas respostas.
  Future<void> registrarSimulado(ResultadoSimulado resultado);

  /// Simulados já feitos, do mais recente para o mais antigo.
  Future<List<ResultadoSimulado>> simulados();

  /// Marca ou desmarca uma questão como favorita, pra reler a explicação
  /// depois — errando ou acertando. Deve voltar rápido mesmo sem internet,
  /// pela mesma razão de [registrar].
  Future<void> favoritar(String questaoId, bool favorita);

  /// Ids das questões favoritas, da mais recente marcada para a mais antiga.
  Future<List<String>> favoritas();

  /// Apaga o progresso de uma matéria: o resumo (última resposta de cada
  /// questão) e o histórico de respostas, de trilha ou de simulado. Não mexe
  /// nas outras matérias, nos favoritos, nem no histórico de simulados
  /// (a nota de uma prova já feita continua valendo como registro).
  Future<void> zerarProgresso(String materia);
}

/// Versão sem persistência: usada nos testes e quando o Firebase não está
/// configurado (o app avisa na tela que o progresso não está sendo salvo).
class ProgressoEmMemoria implements RegistroDeProgresso {
  final respostas = <Resposta>[];
  final _simulados = <ResultadoSimulado>[];
  // Ordem de marcação: a mais recente por último, favoritas() inverte.
  final _favoritos = <String>[];

  @override
  Future<void> registrar(Resposta resposta) async => respostas.add(resposta);

  @override
  Future<Map<String, ResumoUnidade>> resumos() async {
    final porUnidade = <String, Map<String, bool>>{};
    for (final r in respostas) {
      porUnidade.putIfAbsent(r.unidadeId, () => {})[r.questaoId] = r.acertou;
    }
    return {for (final e in porUnidade.entries) e.key: ResumoUnidade(e.value)};
  }

  @override
  Future<void> registrarSimulado(ResultadoSimulado resultado) async {
    _simulados.add(resultado);
    respostas.addAll(resultado.respostas);
  }

  @override
  Future<List<ResultadoSimulado>> simulados() async =>
      [..._simulados]..sort((a, b) => b.inicio.compareTo(a.inicio));

  @override
  Future<void> favoritar(String questaoId, bool favorita) async {
    _favoritos.remove(questaoId);
    if (favorita) _favoritos.add(questaoId);
  }

  @override
  Future<List<String>> favoritas() async => _favoritos.reversed.toList();

  @override
  Future<void> zerarProgresso(String materia) async {
    respostas.removeWhere((r) => r.materia == materia);
  }
}
