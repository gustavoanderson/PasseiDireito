import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/banco.dart';
import 'package:passeidireito/progresso.dart';
import 'package:passeidireito/simulado.dart';
import 'package:passeidireito/trilha.dart';

import 'apoio.dart';

List<Materia> _banco(Map<String, int> porMateria) => [
      for (final e in porMateria.entries)
        Materia(codigo: e.key, questoes: unidadeDeTeste('${e.key}-01', e.key, e.value).questoes),
    ];

void main() {
  test('a distribuição é a da tabela 10.1.1 do edital: 100 questões', () {
    expect(distribuicaoDaProva.values.fold(0, (s, n) => s + n), 100);
    expect(distribuicaoDaProva['adm'], 22);
  });

  test('com banco completo, sorteia exatamente a quantidade do edital de cada matéria', () {
    final simulado = sortearSimulado(_banco({for (final m in distribuicaoDaProva.keys) m: 40}), Random(1));
    expect(simulado, hasLength(100));
    for (final e in distribuicaoDaProva.entries) {
      expect(simulado.where((q) => q.materia == e.key), hasLength(e.value), reason: e.key);
    }
    expect(simulado.map((q) => q.id).toSet(), hasLength(100), reason: 'nenhuma questão repetida');
  });

  test('com banco menor, usa todas as disponíveis, em blocos na ordem da prova', () {
    final simulado = sortearSimulado(_banco({'pc': 5, 'adm': 30, 'const': 2}), Random(1));
    expect(simulado.where((q) => q.materia == 'adm'), hasLength(22));
    expect(simulado.where((q) => q.materia == 'const'), hasLength(2));
    expect(simulado.where((q) => q.materia == 'pc'), hasLength(5));
    expect(simulado.map((q) => q.materia).toSet().toList(), ['adm', 'const', 'pc']);
  });

  test('sorteios diferentes dão provas diferentes', () {
    final banco = _banco({'adm': 60});
    final a = sortearSimulado(banco, Random(1)).map((q) => q.id).toList();
    final b = sortearSimulado(banco, Random(2)).map((q) => q.id).toList();
    expect(a, isNot(equals(b)));
  });

  test('tempo: 5 h para 100 questões; 3 minutos por questão quando há menos', () {
    expect(tempoDoSimulado(100), const Duration(hours: 5));
    expect(tempoDoSimulado(40), const Duration(hours: 2));
    expect(tempoDoSimulado(1), const Duration(minutes: 3));
  });

  test('correção: certa conta, errada e em branco valem zero; nota de 0 a 100', () {
    final questoes = [
      questaoDeTeste('adm-0001', correta: 'A'),
      questaoDeTeste('adm-0002', correta: 'B'),
      questaoDeTeste('adm-0003', correta: 'C'),
      questaoDeTeste('adm-0004', correta: 'D'),
    ];
    final inicio = DateTime(2026, 12, 1, 9);
    final r = corrigirSimulado(
      questoes: questoes,
      escolhas: {0: 'A', 1: 'C', 3: 'D'},
      inicio: inicio,
      fim: inicio.add(const Duration(minutes: 7)),
      tempoPrevisto: const Duration(minutes: 12),
    );
    expect(r.acertos, 2);
    expect(r.emBranco, 1);
    expect(r.nota, 50);
    expect(r.duracao, const Duration(minutes: 7));
    expect(r.respostas.map((x) => x.escolhida), ['A', 'C', semResposta, 'D']);
    expect(r.respostas.every((x) => x.origem == OrigemResposta.simulado && !x.usouDica), isTrue);
    expect(r.respostas.first.unidadeId, 'adm-01');
  });

  test('letras da questão continuam A a E', () => expect(letras, ['A', 'B', 'C', 'D', 'E']));
}
