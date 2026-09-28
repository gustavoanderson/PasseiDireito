/// O progresso da Flávia: cada resposta dada numa trilha, e o resumo por unidade.
///
/// As telas dependem desta interface, nunca do Firestore direto. Assim os
/// testes de tela usam a versão em memória, sem rede e sem relógio real
/// (lição registrada no DevLingo: teste de widget não enxerga I/O real).
library;

class Resposta {
  const Resposta({
    required this.questaoId,
    required this.unidadeId,
    required this.materia,
    required this.escolhida,
    required this.acertou,
    required this.usouDica,
    required this.em,
  });

  final String questaoId;
  final String unidadeId;
  final String materia;
  final String escolhida;
  final bool acertou;
  final bool usouDica;
  final DateTime em;
}

/// Situação de uma unidade: para cada questão já respondida, se a ÚLTIMA
/// resposta foi certa. Refazer a unidade substitui o resultado anterior,
/// porque o que interessa é se ela sabe hoje, não se sabia na primeira vez.
class ResumoUnidade {
  const ResumoUnidade(this.ultimaPorQuestao);

  final Map<String, bool> ultimaPorQuestao;

  int get feitas => ultimaPorQuestao.length;
  int get acertos => ultimaPorQuestao.values.where((a) => a).length;
}

abstract interface class RegistroDeProgresso {
  /// Grava uma resposta. Deve voltar rápido mesmo sem internet: a trilha não
  /// pode travar no "Continuar" esperando o servidor.
  Future<void> registrar(Resposta resposta);

  /// Resumo de todas as unidades já iniciadas, pelo id da unidade.
  Future<Map<String, ResumoUnidade>> resumos();
}

/// Versão sem persistência: usada nos testes e quando o Firebase não está
/// configurado (o app avisa na tela que o progresso não está sendo salvo).
class ProgressoEmMemoria implements RegistroDeProgresso {
  final respostas = <Resposta>[];

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
}
