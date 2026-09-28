import 'dart:math';

import 'banco.dart';
import 'progresso.dart';
import 'trilha.dart';

/// Quantas questões de cada matéria a prova objetiva tem (edital, tabela 10.1.1).
/// A ordem é a da tabela; o simulado apresenta as questões nesta ordem de
/// blocos, como o caderno real, mas sem nomear a matéria na tela.
const distribuicaoDaProva = {
  'adm': 22,
  'const': 19,
  'trib': 19,
  'pc': 19,
  'urb': 7,
  'trab': 5,
  'prev': 3,
  'pen': 3,
  'emp': 3,
};

/// 5 horas para 100 questões (edital, item 11.23): 3 minutos por questão.
const duracaoDaProva = Duration(hours: 5);

/// Sorteia o simulado: de cada matéria, a quantidade do edital, ou todas as
/// disponíveis se o banco ainda tiver menos. A ordem dentro do bloco também é
/// sorteada, para a prova nunca se repetir.
List<Questao> sortearSimulado(List<Materia> materias, Random sorteio) {
  final porCodigo = {for (final m in materias) m.codigo: m};
  return [
    for (final e in distribuicaoDaProva.entries)
      if (porCodigo[e.key] case final m?) ...([...m.questoes]..shuffle(sorteio)).take(e.value),
  ];
}

/// Tempo do simulado: o da prova quando ele tem as 100 questões; proporcional
/// (3 minutos por questão) enquanto o banco for menor.
Duration tempoDoSimulado(int questoes) {
  final total = distribuicaoDaProva.values.fold(0, (s, n) => s + n);
  return questoes >= total ? duracaoDaProva : duracaoDaProva * questoes ~/ total;
}

/// Corrige o simulado. [escolhas] vai do índice da questão à letra marcada;
/// questão sem escolha fica em branco e vale zero, como na prova.
ResultadoSimulado corrigirSimulado({
  required List<Questao> questoes,
  required Map<int, String> escolhas,
  required DateTime inicio,
  required DateTime fim,
  required Duration tempoPrevisto,
}) {
  return ResultadoSimulado(
    inicio: inicio,
    duracao: fim.difference(inicio),
    tempoPrevisto: tempoPrevisto,
    respostas: [
      for (var i = 0; i < questoes.length; i++)
        Resposta(
          questaoId: questoes[i].id,
          unidadeId: questoes[i].unidadeId,
          materia: questoes[i].materia,
          escolhida: escolhas[i] ?? semResposta,
          acertou: escolhas[i] == questoes[i].correta,
          usouDica: false,
          em: fim,
          origem: OrigemResposta.simulado,
        ),
    ],
  );
}
